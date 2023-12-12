# Construction states

# Table of Contents

- [State](#state)
- [Toggle mesh](#toggle-mesh)
- [Progression mesh](#progression-mesh)
- [Progression shader mesh](#progression-shader-mesh)
- [Inputs](#inputs)

## State

Used for building stages, if \<input\>s are defined it will await input materials and proceed to process deliveries and start building according to processPerHour. If no inputs are defined it will automatically continue to next state.

States are processed in order defined in the XML from top to bottom.


```xml
<construction>
    <states>
        <state title="$l10n_buildWallsTitle">
            ...
        </state>

        <state title="$l10n_buildRoofTitle">
            ...
        </state>
    </states>
</construction>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| title | string | No | nil | Text to be shown in GUI. i18n compatible, can use strings from mod. |
| processingSample | string | No | nil | Override the default processing sample. To disable processing sound for specific state use ```processingSample="nil"```

## Toggle mesh

A toggle mesh entry will be processed when the construction state is activated.

```xml
<state>
    <toggleMesh node="woodBeams_col" active="false" />
    <toggleMesh node="concreteFoundation_col" active="true" updatePhysics="true" collisionMask="#ff" />
    ...
</state>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |
| active | boolean | Yes | | Whether mesh is active or not |
| updateChildren | boolean | No | false | Apply on all direct child nodes instead of set node. |
| updatePhysics | boolean | No | false | Add node to physics if ```active="true"```, remove from physics if ```active="false"``` |
| collisionMask | string \| int | No | nil | Set collision mask of node. #hex or int from Giants Editor. |
| rigidBody | string | No | nil | Set rigid body type of node. Values: ```NONE``` \| ```STATIC``` \| ```DYNAMIC``` \| ```KINEMATIC```

## Progression mesh

Activate (visibility) child meshes based on total state processing progress.

```xml
<state ...>
    ...
    <meshes>
        <mesh node="woodBeams_vis" />
    </meshes>
</state>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |
| startIndex | int | No | 0 | Start at child index |
| stopIndex | int | No | nil | Stop at child index |
| direction | int | No | 1 | Iteration direction. 1 for positive, -1 for negative |

## Progression shader mesh

Same principle as [Progression mesh](#progression-mesh), but referenced node must be using FS22 building(?) shader variant ```hideByIndex```.

```xml
<state>
    ...
    <meshes>
        <shaderMesh node="woodPanels_vis" />
    </meshes>
</state>
```

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| node            | node   | Yes      |         | I3D node mapping name/index path        |
| startIndex | int | No | 0 | Start at child index |
| stopIndex | int | Yes |  | Stop at child index |
| direction | int | No | 1 | Shader visibility direction. 1 for positive, -1 for negative |

## Inputs

```xml
<state>
    ...
    <inputs>
        <input fillType="WOODBEAM" amount="4000" processPerHour="8000" />
    </inputs>
    ...
</state>
```
In this example the state required 4000 of fillType woodbeams to be delivered and it will take in total 30 ingame minutes to process all woodbeams.

### Attributes

| Name            | Type   | Required | Default | Description                             |
|-----------------|--------|----------|---------|-----------------------------------------|
| fillType | string | Yes | | Name of fill type (case-sensitive) |
| amount | float | Yes | | Amount required to deliver |
| processPerHour | float | Yes | | Amount processed per ingame hour |
| deliveryAreaIndex | int | No | 1 | Specify delivery area used by input |