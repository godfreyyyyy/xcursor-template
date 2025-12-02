Hotspots are points were your logical cursor is at.
They are provided in percent values to be not have to provide pixel locations
for individual cursor resolutions.

File with hotspot must be named same as source SVG file, but with `.hotspot`
file extension.

For example, `arrow.svg` that can be found in `src` directory has hotspot at
(0;50).

But in actuall `.hotspot` file it will look like that:
```
0 50
```
