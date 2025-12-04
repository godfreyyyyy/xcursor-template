Frametimes for animated cursors are defined in milliseconds on every line
for each animation frame.

File with frametimes must be named same as a directory with animated cursor
frames, but with `.frametime` file extension.

If a number of defined frametimes is less than a number of animation frames,
missing frametimes will be set to a `$DEFAULT_FRAMETIME` which is set in
`var.sh`.

If a number of defined frametimes is greater than a number of animation frames,
extra frametimes will be ignored.

Example of `.frametime` file:
```
25
35
40
55
65
```
This will set time of first frame to 25, second to 35, third to 40, etc.
