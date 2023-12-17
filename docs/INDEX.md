# Documentation

# Table of Contents

- [Add specialization to placeable type](#add-specialization-to-placeable-type)
- [Placeable XML](#placeable-xml)
- [Activation trigger](#activation-trigger)
- [Map hotspot](#map-hotspot)
- [Construction audio samples](#construction-audio-samples)
  - [Sample](#sample)
- [Construction meshes](#construction-meshes)
  - [Mesh](#mesh)
- [Console commands](#console-commands)

Further implementation details:
- → [Delivery area](DELIVERY_AREA.md)
- → [Construction states](CONSTRUCTION_STATES.md)

Documentation files:
- 🗎 [XML example file](./examples/placeable_example.xml)
- 🗎 [XSD validation schema](./placeable_construction.xsd)
- 🗎 [HTML schema](./placeable_construction.html)

## Add specialization to placeable type

```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<modDesc version="...">
    ...
    <placeableTypes>
        <!-- Extend parent type, can be anything -->
        <type name="constructionBuilding" parent="simplePlaceable">
            <!-- Add other specializations you want for your placeable -->
            <specialization name="infoTrigger" />

            <!-- Add construction as last entry to type -->
            <specialization name="FS22_1_PlaceableConstruction.construction" />
        </type>
    </placeableTypes>
    ...
</modDesc>
```

## Placeable XML


```xml
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<placeable ...>
    ...
    <construction price="12000">
        <!-- Required -->
        <activationTrigger node="..." />

        <!-- Optional -->
        <hotspot icon="..." iconUVs="..." />

        <!-- Optional -->
        <samples node="..." processingSample="carpenterWork" deliverySample="metalClose" completionSample="stadiumFanfare">
            ...
        </samples>

        <!-- Optional -->
        <meshes>
            <activate status="PREVIEW">
                <mesh node="previewBox" />
            </activate>

            <activate status="ACTIVE">
                <mesh node="constructionSign_vis" />
                <mesh node="constructionSign_col" updatePhysics="true" collisionMask="#ff" />
            </activate>

            <activate status="PROCESSING">
                <mesh node="warningDecal_vis" />
            </activate>

            <activate status="COMPLETED">
                <mesh node="welcomeSign_vis" />
                <mesh node="welcomeSign_col" updatePhysics="true" />
            </activate>
        </meshes>

        <!-- Required -->
        <deliveryAreas>
            ...
        </deliveryAreas>

        <!-- Required -->
        <states>
            ...
        </states>
    </construction>
</placeable>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| price           | int    | No  | nil | Optional override buy and sell price for placeable. When construction is completed the storeData.price will be used as sell price. |

## Activation trigger

Player activation trigger for delivering object materials, quick access for construction in GUI and showing HUD to nearby player(s). The collisionMask of node must have bit ```20``` (TRIGGER_PLAYER) set in order for it to function.

```xml
<construction>
    <activationTrigger node="constructionActivationTrigger" />
</construction>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |

## Map hotspot

Set a custom map construction hotspot icon. Not required to add to XML, only used if you want to use custom icon texture to replace the default.

**NOTE**: This is a hotspot separate from the standard placeable hotspots.

```xml
<construction>
    <hotspot icon="textures/customHotspotIcon.png" />
</construction>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| icon            | string | No       | nil | Path to icon texture file relative to placeable mod root folder. |
| iconUVs         | string | No       | "0 0 1 1" | Set icon texture UVs. RefSize is 1024x1024px. |

## Construction audio samples

```xml
<construction>
    <samples node="soundNode" processingSample="carpenterWork" deliverySample="metalClose" completionSample="stadium">
        <sample name="carpenterWork" file="$data/sounds/placeables/carpenterWork.wav" loops="0" fadeOut="2" />
        <sample name="fenceWork" file="$data/sounds/placeables/fenceWoodImp.wav" loops="0" fadeOut="2" />
        <sample name="metalWork" file="$data/sounds/placeables/fenceMetalImp.wav" loops="0" fadeOut="2" />
        <sample name="stadium" file="$data/sounds/maps/mapUS/details/baseballStadiumUS01.wav" />
        <sample name="metalClose" file="$data/sounds/animations/impacts/metalClose01.wav">
            <volume outdoor="8" indoor="4" />
        </sample>
    </samples>
</construction>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | No      | Placeable I3D root node | I3D node mapping name/index path |
| processingSample| string | No | nil | Default audio sample to play when processing input materials. Should be a sample with loops="0" |
| deliverySample  | string | No | nil | Audio sample to play when delivering object materials. |
| completionSample| string | No | nil | Audio sample to play when completing construction. |

### Sample

```xml
<construction>
    <samples ...>
        <sample name="carpenterWork" file="$data/sounds/placeables/carpenterWork.wav" loops="0" fadeOut="2" />
    </samples>
</construction>
```

Loading samples from mod is also supported:

```xml
<construction>
    <samples ...>
        <sample name="myCustomSample" file="sounds/customSound.wav" loops="0" fadeOut="2" />
    </samples>
</construction>
```

#### Attributes
| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| name | string | Yes |  | Unique name to be referenced. |

Sample implements the rest of base game sample specifications used by i.e Vehicles (SoundManager.registerSampleXMLPaths).

**NOTE:** ```linkNode``` and ```linkNodeOffset``` attributes are excluded.

## Construction meshes

Activate and deactivate specific nodes based on construction status. All meshes regardless of status type are deactivated when loading placeable.


```xml
<construction>
    <meshes>
        <activate status="PREVIEW">
            ...
        </activate>
        <activate status="ACTIVE">
            ...
        </activate>
        <activate status="PROCESSING">
            ...
        </activate>
        <activate status="COMPLETED">
            ...
        </activate>
    </meshes>
</construction>
```

### Attributes
| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| status          | string | Yes |  | Construction status condition ```PREVIEW``` \| ```ACTIVE``` \| ```PROCESSING``` \| ```COMPLETED```|

### Conditions


```ini
status="PREVIEW"
```
Meshes are activated only when previewing in construction menu, deactivated when construction is placed.

```ini
status="ACTIVE"
```
Meshes are activated when starting construction, and deactivated when construction is completed.
```ini
status="PROCESSING"
```
Meshes are activated when any of the states are processing input materials.
```ini
status="COMPLETED"
```
Meshes are deactivated when starting construction, and activated when construction is completed.


### Mesh


```xml
<construction>
    <meshes>
        <activate status="ACTIVE">
            <mesh node="constructionSign_vis" />
            <mesh node="constructionSign_col" updatePhysics="true" />
            <mesh node="constructionBarrier_col" updatePhysics="true" collisionMask="#ff" />
        </activate>
    </meshes>
</construction>
```

#### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node | node | Yes | | I3D node mapping name/index path |
| updateChildren | boolean | No | false | Apply on all direct child nodes instead of set node |
| updatePhysics | boolean | No | false | Add node to physics when activated, remove when deactivated. |
| collisionMask | string \| int | No | nil | Set collision mask of node when activated. #hex or int from Giants Editor.
| rigidBody | string | No | nil | Set rigid body type of node when activated.  If defined it will set rigid body to ```NONE``` when deactivated. Values: ```NONE``` \| ```STATIC``` \| ```DYNAMIC``` \| ```KINEMATIC```.

## Console commands

*Only available in the debug build.*

```csNextState``` Force construction to proceed to next state.

```csDeliverAll``` Deliver 100% of products to all inputs. [Server side only]

```csDeliverInput <index> [<percentage 0..1>]``` Deliver products to a specific input. Optional percentage (default: 1) [Server side only]