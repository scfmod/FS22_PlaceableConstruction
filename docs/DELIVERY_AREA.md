# Construction delivery area

At least one (1) delivery area is required.

# Table of Contents

- [Delivery area](#delivery-area)
- [Object trigger](#object-trigger)
- [Fill trigger](#fill-trigger)
- [Meshes](#meshes)
- [Examples](#examples)


## Delivery area

```xml
<construction>
    <deliveryAreas>
        <deliveryArea alwaysActive="true">
            ...
        </deliveryArea>
    </deliveryAreas>
</construction>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| alwaysActive    | boolean | No | false | If set to true then the delivery area will be enabled during construction. If set to false delivery area will be enabled only when required by active input(s). |

Delivery area must have at least one trigger defined.
See:
- [Object trigger](#object-trigger)
- [Fill trigger](#fill-trigger)

## Object trigger

Used for delivering objects such as pallets and the like. The collisionMask of node must have bit ```21``` (TRIGGER_VEHICLE) set in order for it to function.

```xml
<deliveryArea>
    <objectTrigger node="..." />
</deliveryArea>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |

## Fill trigger

Used for delivering dischargeable materials. The collisionMask of node must have bit ```30``` (FILLABLE) set in order for it to function.

```xml
<deliveryArea>
    <fillTrigger node="..." />
</deliveryArea>
```

### Attributes
| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |

## Meshes

```xml
<deliveryArea>
    ...
    <meshes>
        <mesh node="deliveryStand_vis" updateChildren="true" />
        <mesh node="deliveryStand_col" updateChildren="true" updatePhysics="true" collisionMask="#ff" />
    </meshes>
</deliveryArea>
```

### Attributes
| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |
| updateChildren | boolean | No | false | Apply on all direct child nodes instead of set node. |
| updatePhysics | boolean | No | false | Add node to physics when activated, remove when deactivated. |
| collisionMask | string \| int | No | nil | Set collision mask of node when activated. #hex or int from Giants Editor. |
| rigidBody | string | No | nil | Set rigid body type of node when activated. If defined it will set rigid body to ```NONE``` when deactivated. Values: ```NONE``` \| ```STATIC``` \| ```DYNAMIC``` \| ```KINEMATIC```


## Examples

Two delivery areas, one which is always active for delivering materials via objects (pallets, vehicles etc.).
The other one is for delivering materials via discharge and is only active when required by active input(s).

```xml
<placeable>
    <construction>
        ...
        <deliveryAreas>
            <deliveryArea alwaysActive="true">
                <objectTrigger node="palletDeliveryNode" />

                <meshes>
                    <mesh node="deliveryStand_vis" updateChildren="true" />
                    <mesh node="deliveryStand_col" updateChildren="true" updatePhysics="true" collisionMask="#ff">
                </meshes>
            </deliveryArea>

            <deliveryArea>
                <fillTrigger node="dischargeDeliveryNode" />

                <meshes>
                    <mesh node="gravelMound_vis" />
                    <mesh node="gravelMound_col" updatePhysics="true" collisionMask="#ff">
                </meshes>
            </deliveryArea>
        </deliveryAreas>
    </construction>
</placeable>
```

One delivery area which is always active during construction and allows both delivery methods.

```xml
<placeable>
    <construction>
        ...
        <deliveryAreas>
            <deliveryArea alwaysActive="true">
                <objectTrigger node="palletDeliveryNode" />
                <fillTrigger node="dischargeDeliveryNode" />

                <meshes>
                    <mesh node="deliveryStand_vis" updateChildren="true" />
                    <mesh node="deliveryStand_col" updateChildren="true" updatePhysics="true" collisionMask="#ff">
                </meshes>
            </deliveryArea>
        </deliveryAreas>
    </construction>
</placeable>
```