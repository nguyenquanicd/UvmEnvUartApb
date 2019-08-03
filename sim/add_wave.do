onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testTop/dut_top/pclk_0
add wave -noupdate /testTop/dut_top/preset_n_0
add wave -noupdate /testTop/dut_top/pwrite_0
add wave -noupdate /testTop/dut_top/psel_0
add wave -noupdate /testTop/dut_top/penable_0
add wave -noupdate /testTop/dut_top/paddr_0
add wave -noupdate /testTop/dut_top/pwdata_0
add wave -noupdate /testTop/dut_top/pstrb_0
add wave -noupdate /testTop/dut_top/prdata_0
add wave -noupdate /testTop/dut_top/pready_0
add wave -noupdate /testTop/dut_top/pslverr_0
add wave -noupdate /testTop/dut_top/ctrl_if_0
add wave -noupdate /testTop/dut_top/pclk_1
add wave -noupdate /testTop/dut_top/preset_n_1
add wave -noupdate /testTop/dut_top/pwrite_1
add wave -noupdate /testTop/dut_top/psel_1
add wave -noupdate /testTop/dut_top/penable_1
add wave -noupdate /testTop/dut_top/paddr_1
add wave -noupdate /testTop/dut_top/pwdata_1
add wave -noupdate /testTop/dut_top/pstrb_1
add wave -noupdate /testTop/dut_top/prdata_1
add wave -noupdate /testTop/dut_top/pready_1
add wave -noupdate /testTop/dut_top/pslverr_1
add wave -noupdate /testTop/dut_top/ctrl_if_1
add wave -noupdate /testTop/dut_top/uart_0to1
add wave -noupdate /testTop/dut_top/uart_1to0
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {55 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 218
configure wave -valuecolwidth 145
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {16 ns} {157 ns}
