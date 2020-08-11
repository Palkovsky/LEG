`ifndef FIXPOINT
`define FIXPOINT

`define FIXPOINT_WIDTH 16
`define FIXPOINT_MULT  2048
`define FIXPOINT_MAX   ((1 << (`FIXPOINT_WIDTH - 1)) - 1)
`define FIXPOINT_MIN   (-(1 << (`FIXPOINT_WIDTH - 1)))

function logic[`FIXPOINT_WIDTH:0] fixpoint_add(logic[`FIXPOINT_WIDTH - 1:0] a, logic[`FIXPOINT_WIDTH - 1:0] b);
   automatic logic[`FIXPOINT_WIDTH:0] c = $signed(a) + $signed(b);
   if ($signed(c) > `FIXPOINT_MAX) begin
      return `FIXPOINT_MAX;
   end
   if ($signed(c) < `FIXPOINT_MIN) begin
      return `FIXPOINT_MIN;
   end
   return c;
endfunction

function logic[`FIXPOINT_WIDTH:0] fixpoint_mul(logic[`FIXPOINT_WIDTH - 1:0] a, logic[`FIXPOINT_WIDTH - 1:0] b);
   automatic logic[`FIXPOINT_WIDTH * 2 - 1:0] c = $signed(a) * $signed(b);
   c /= `FIXPOINT_MULT;
   if ($signed(c) > `FIXPOINT_MAX) begin
      return `FIXPOINT_MAX;
   end
   if ($signed(c) < `FIXPOINT_MIN) begin
      return `FIXPOINT_MIN;
   end
   return c;
endfunction

function logic[`FIXPOINT_WIDTH:0] fixpoint_div(logic[`FIXPOINT_WIDTH - 1:0] a, logic[`FIXPOINT_WIDTH - 1:0] b);
   automatic logic[`FIXPOINT_WIDTH * 2 - 1:0] c = $signed(a) * `FIXPOINT_MULT / $signed(b);
   if ($signed(c) > `FIXPOINT_MAX) begin
      return `FIXPOINT_MAX;
   end
   if ($signed(c) < `FIXPOINT_MIN) begin
      return `FIXPOINT_MIN;
   end
   return c;
endfunction

`endif
