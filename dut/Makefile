#del_ut:
#	emacs --batch uart_top.v -f verilog-batch-delete-auto
#build_ut:
#	emacs --batch uart_top.v -f verilog-batch-auto
del_w:
	emacs --batch m_fpt_uart_wrapper.sv -f verilog-batch-delete-auto
build_w:
	emacs --batch m_fpt_uart_wrapper.sv -f verilog-batch-auto

#all_ut: del_ut build_ut
all_w: del_w build_w
#all: all_ut all_w