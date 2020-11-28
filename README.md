# snowFlake.zig
snowFlake in zig lang

# how to use 
```
const snowFlake = @import("./snowFlake.zig").snowFlake;

var sf = snowFlake.init(startTimeInMs, workerId);  

var id = sf.get();  

```
