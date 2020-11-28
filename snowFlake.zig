const std = @import("std");

const snowFlake = struct {
    startTime: u64,
    lastvalue: u64=0,

    const Self = @This();
    const worker_mask = 0x3ff;

    pub fn init(startTime: u64, workerId: u64) Self {
        var v :Self = .{.startTime = startTime, .lastvalue = workerId <<12};
        return v;
    }

    inline fn extractWorkerId(value: u64) u64{
        return (value >> 12) & worker_mask;
    }

    inline fn extractTimestamp(value: u64) u64{
        return (value >> 22);
    }
    
    inline fn extractSequence(value: u64) u64{
        return (value & 0xfff);
    }
    
    pub fn format(value: *const Self, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "{} {{ .startTime = {}, .workerId = {}, .timestamp = {}, .sequence = {} }}", .{comptime @typeName(Self) ++ "{ ", 
            value.startTime, extractWorkerId(value.lastvalue), 
            extractTimestamp(value.lastvalue), extractSequence(value.lastvalue)});
    }

    fn tryGen(startTime:u64, value: u64) u64 {
        var curr_ts = @bitCast(u64, std.time.milliTimestamp()) - startTime;

        const prev_ts = extractTimestamp(value);
        var sequence = extractSequence(value);
        const workerId = extractWorkerId(value);

        var mask = ~@intCast(u64, worker_mask);

        if((value & mask) == 0){
            sequence = 0;
        } else if (curr_ts == prev_ts) {
            sequence = sequence + 1;
            if(sequence >= 0x1000){
                sequence = 0;
                var now = curr_ts;
                while(curr_ts == now){
                    now = @bitCast(u64, std.time.milliTimestamp()) - startTime;
                }
                curr_ts = now;
            }
        } else {
            sequence = 0;
        }
        return (curr_ts<<22) | ((workerId <<12)& (worker_mask<<12)) | (sequence & 0x0fff);
    }
    
    pub fn get(self: *Self) u64 {
        var old_value = self.lastvalue;
        while(true){
            var new_value = tryGen(self.startTime, old_value);
            
            var o = @cmpxchgWeak(u64, &self.lastvalue, old_value, new_value, .Acquire, .Acquire);
            if(o)|v|{
                old_value = v;
                continue;
            }
            return new_value;
        }
    }
};