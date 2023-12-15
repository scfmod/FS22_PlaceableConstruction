---@meta

---@class ClassObject
---@field isa fun(self, other: any):boolean
---@field class fun():any
---@field superClass fun():any

---@class DeliveryObject : Vehicle, FillUnit, Pallet, Mountable, ClassObject

---@class Sample
---@field is2D boolean
---@field sampleName string
---@field filename string
---@field isGlsFile boolean
---@field linkNode number
---@field current any
---@field audioGroup number
---@field volumeScale number
---@field offsets table
---@field outdoorAttributes any

---@class ConstructionSettings
---@field requireFarmAccess boolean
---
---@field enableVisitButton boolean
---@field enablePriceOverride boolean
---@field enableHotspots boolean
---@field enableBuyingPallets boolean
---@field enableHotspotsWhenCompleted boolean

---@class ConstructionUserSettings
---@field hudPosition HUDPosition
---@field enableSound boolean
---@field enableNotifications boolean

---@class StoreItem
---@field name string
---@field rawXMLFilename string
---@field baseDir string
---@field xmlFilename string
---@field xmlFilenameLower string
---@field showInStore boolean
