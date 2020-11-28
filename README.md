# snowFlake.zig
snowFlake for zig lang

# how to use
download and put into your project.  
```
const snowFlake = @import("./snowFlake.zig").snowFlake;

var sf = snowFlake.init(startTimeInMs, workerId);  

var id = sf.get();  

```
