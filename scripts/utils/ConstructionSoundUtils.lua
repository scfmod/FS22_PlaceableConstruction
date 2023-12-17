---@enum SampleType
SampleType = {
    DELIVERY = 1,
    PROCESSING = 2,
    COMPLETION = 3
}

---@class ConstructionSoundUtils
ConstructionSoundUtils = {}

---@param type SampleType
---@param placeable PlaceableConstruction
function ConstructionSoundUtils.playSample(type, placeable)
    if g_construction:getIsSoundEnabled() then
        local sample = placeable:getSampleByType(type)

        if sample ~= nil and not g_soundManager:getIsSamplePlaying(sample) then
            g_soundManager:playSample(sample)
            g_construction:debug('playSample: %s', sample.sampleName)
        end
    end
end

---@param type SampleType
---@param placeable PlaceableConstruction
function ConstructionSoundUtils.stopSample(type, placeable)
    local sample = placeable:getSampleByType(type)

    if sample ~= nil and g_soundManager:getIsSamplePlaying(sample) then
        g_soundManager:stopSample(sample)
        g_construction:debug('stopSample: %s', sample.sampleName)
    end
end

---@param xmlFile XMLFile
---@param key string
---@param placeable PlaceableConstruction
---@param soundNode number
---@return Sample | nil
function ConstructionSoundUtils.loadSampleFromXML(xmlFile, key, placeable, soundNode)
    local loops = nil
    local xmlFileHandle = xmlFile:getHandle()
    local audioGroup = AudioGroup.ENVIRONMENT

    ---@type Sample
    ---@diagnostic disable-next-line: missing-fields
    local sample = {
        is2D = false
    }

    ---@type string
    local name = xmlFile:getValue(key .. '#name')

    sample.sampleName = 'construction_' .. name

    local template = xmlFile:getValue(key .. '#template')

    if template ~= nil then
        sample = g_soundManager:loadSampleAttributesFromTemplate(sample, template, placeable.baseDirectory, loops, xmlFileHandle, key)
    end

    if not g_soundManager:loadSampleAttributesFromXML(sample, xmlFileHandle, key, placeable.baseDirectory, loops) then
        Logging.error('ConstructionSoundUtils.loadSampleFromXML() loadSampleAttributesFromXML function failed')
        return
    end

    ---@diagnostic disable-next-line: assign-type-mismatch
    sample.filename = Utils.getFilename(sample.filename, placeable.baseDirectory)
    sample.isGlsFile = sample.filename:find(".gls") ~= nil
    sample.linkNode = soundNode
    sample.current = sample.outdoorAttributes
    sample.audioGroup = audioGroup

    if not sample.filename:startsWith('data') and not fileExists(sample.filename) then
        Logging.warning('Sample file not found: %s', sample.filename)
        return
    end

    g_soundManager:createAudioSource(sample, sample.filename)

    sample.offsets = {
        lowpassGain = 0,
        pitch = 0,
        volume = 0
    }

    return sample
end

---@param xmlFile XMLFile
---@param key string
---@param placeable PlaceableConstruction
---@param soundNode number | nil
function ConstructionSoundUtils.loadSamples(xmlFile, key, placeable, soundNode)
    ---@type table<string, Sample>
    local result = {}

    if soundNode ~= nil then
        xmlFile:iterate(key .. '.sample', function(_, sampleKey)
            local name = xmlFile:getValue(sampleKey .. '#name')

            if result[name] == nil then
                local sample = ConstructionSoundUtils.loadSampleFromXML(xmlFile, sampleKey, placeable, soundNode)

                if sample ~= nil then
                    result[name] = sample
                end
            else
                Logging.xmlWarning(xmlFile, 'Duplicate sample name "%s": %s', name, sampleKey)
            end
        end)
    end

    return result
end

---@param schema XMLSchema
---@param key string
function ConstructionSoundUtils.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#node', 'Sound location node', 'rootNode')
    schema:register(XMLValueType.STRING, key .. '#processingSample', 'Sample name for processing materials')
    schema:register(XMLValueType.STRING, key .. '#deliverySample', 'Sample name for material delivery (does not apply to dischargeable)')
    schema:register(XMLValueType.STRING, key .. '#completionSample', 'Sample name for construction completed')

    local basePath = key .. '.sample(?)'
    schema:register(XMLValueType.STRING, basePath .. '#name', 'Sample name to be used as reference', nil, true)
    schema:register(XMLValueType.STRING, basePath .. "#template", "Sound template name")
    schema:register(XMLValueType.STRING, basePath .. "#parent", "Parent sample for heredity")
    schema:register(XMLValueType.STRING, basePath .. "#file", "Path to sound sample")
    schema:register(XMLValueType.FLOAT, basePath .. "#outerRadius", "Outer radius", 5)
    schema:register(XMLValueType.FLOAT, basePath .. "#innerRadius", "Inner radius", 80)
    schema:register(XMLValueType.INT, basePath .. "#loops", "Number of loops (0 = infinite)", 1)
    schema:register(XMLValueType.BOOL, basePath .. "#supportsReverb", "Flag to disable reverb", true)
    schema:register(XMLValueType.BOOL, basePath .. "#isLocalSound", "While set for vehicle sounds it will only play for the player currently using the vehicle", false)
    schema:register(XMLValueType.BOOL, basePath .. "#debug", "Flag to enable debug rendering", false)
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeIn", "Fade in time in seconds", 0)
    schema:register(XMLValueType.FLOAT, basePath .. "#fadeOut", "Fade out time in seconds", 0)
    schema:register(XMLValueType.FLOAT, basePath .. ".volume#indoor", "Indoor volume", 0.8)
    schema:register(XMLValueType.FLOAT, basePath .. ".pitch#indoor", "Indoor pitch", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".lowpassGain#indoor", "Indoor lowpass gain", 0.8)
    schema:register(XMLValueType.FLOAT, basePath .. ".lowpassCutoffFrequency#indoor", "Indoor lowpass cutoff frequency", 5000)
    schema:register(XMLValueType.FLOAT, basePath .. ".lowpassResonance#indoor", "Indoor lowpass resonance", 2)
    schema:register(XMLValueType.FLOAT, basePath .. ".lowpassCutoffFrequency#outdoor", "Outdoor lowpass cutoff frequency", 5000)
    schema:register(XMLValueType.FLOAT, basePath .. ".lowpassResonance#outdoor", "Outdoor lowpass resonance", 2)
    schema:register(XMLValueType.FLOAT, basePath .. ".volume#outdoor", "Outdoor volume", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".pitch#outdoor", "Outdoor pitch", 1)
    schema:register(XMLValueType.FLOAT, basePath .. ".lowpassGain#outdoor", "Outdoor lowpass gain", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#volumeScale", "Additional scale that is applied on the volume attributes", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#pitchScale", "Additional pitch that is applied on the volume attributes", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#lowpassGainScale", "Additional lowpass gain that is applied on the volume attributes", 1)
    schema:register(XMLValueType.FLOAT, basePath .. "#loopSynthesisRPMRatio", "Ratio between rpm in the gls file and actual rpm of the motor (e.g. 0.9: max. rpm in the gls file will be reached at 90% of motor rpm)", 1)
    SoundManager.registerModifierXMLPaths(schema, basePath .. ".volume")
    SoundManager.registerModifierXMLPaths(schema, basePath .. ".pitch")
    SoundManager.registerModifierXMLPaths(schema, basePath .. ".lowpassGain")
    SoundManager.registerModifierXMLPaths(schema, basePath .. ".loopSynthesisRpm")
    SoundManager.registerModifierXMLPaths(schema, basePath .. ".loopSynthesisLoad")
    schema:register(XMLValueType.FLOAT, basePath .. ".randomization(?)#minVolume", "Min volume")
    schema:register(XMLValueType.FLOAT, basePath .. ".randomization(?)#maxVolume", "Max volume")
    schema:register(XMLValueType.FLOAT, basePath .. ".randomization(?)#minPitch", "Max pitch")
    schema:register(XMLValueType.FLOAT, basePath .. ".randomization(?)#maxPitch", "Max pitch")
    schema:register(XMLValueType.FLOAT, basePath .. ".randomization(?)#minLowpassGain", "Max lowpass gain")
    schema:register(XMLValueType.FLOAT, basePath .. ".randomization(?)#maxLowpassGain", "Max lowpass gain")
    schema:register(XMLValueType.BOOL, basePath .. ".randomization(?)#isInside", "Randomization is applied inside", true)
    schema:register(XMLValueType.BOOL, basePath .. ".randomization(?)#isOutside", "Randomization is applied outside", true)
    schema:register(XMLValueType.STRING, basePath .. ".sourceRandomization(?)#file", "Path to sound sample")
end
