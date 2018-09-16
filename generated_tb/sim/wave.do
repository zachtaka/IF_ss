onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /top_tb/th/uut/clk
add wave -noupdate -radix unsigned /top_tb/th/uut/rst_n
add wave -noupdate -divider -height 20 {Output Interface}
add wave -noupdate -radix unsigned /top_tb/th/uut/data_out
add wave -noupdate -radix unsigned -childformat {{/top_tb/th/uut/packet_a.pc -radix unsigned} {/top_tb/th/uut/packet_a.data -radix unsigned} {/top_tb/th/uut/packet_a.taken_branch -radix unsigned}} -expand -subitemconfig {/top_tb/th/uut/packet_a.pc {-height 15 -radix unsigned} /top_tb/th/uut/packet_a.data {-height 15 -radix unsigned} /top_tb/th/uut/packet_a.taken_branch {-height 15 -radix unsigned}} /top_tb/th/uut/packet_a
add wave -noupdate -radix unsigned -childformat {{/top_tb/th/uut/packet_b.pc -radix unsigned} {/top_tb/th/uut/packet_b.data -radix unsigned} {/top_tb/th/uut/packet_b.taken_branch -radix unsigned}} -expand -subitemconfig {/top_tb/th/uut/packet_b.pc {-height 15 -radix unsigned} /top_tb/th/uut/packet_b.data {-height 15 -radix unsigned} /top_tb/th/uut/packet_b.taken_branch {-height 15 -radix unsigned}} /top_tb/th/uut/packet_b
add wave -noupdate -radix unsigned /top_tb/th/uut/valid_o
add wave -noupdate -radix unsigned /top_tb/th/uut/ready_in
add wave -noupdate -divider -height 20 Other
add wave -noupdate /top_tb/th/uut/is_return
add wave -noupdate /top_tb/th/uut/is_return_fsm
add wave -noupdate -radix unsigned /top_tb/th/uut/instruction_out
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/gl_history
add wave -noupdate /top_tb/th/uut/taken_branch_1
add wave -noupdate /top_tb/th/uut/taken_branch_2
add wave -noupdate /top_tb/th/uut/half_access
add wave -noupdate -divider -height 20 {ICache Interface}
add wave -noupdate -radix unsigned /top_tb/th/IF_if_0/trans_id_dbg
add wave -noupdate -radix unsigned /top_tb/th/uut/current_PC
add wave -noupdate -radix unsigned /top_tb/th/uut/Hit_cache
add wave -noupdate -radix unsigned /top_tb/th/uut/Miss
add wave -noupdate -radix unsigned /top_tb/th/uut/partial_access
add wave -noupdate -radix unsigned /top_tb/th/uut/partial_type
add wave -noupdate -radix unsigned /top_tb/th/uut/fetched_data
add wave -noupdate -divider -height 20 {Flush Interface}
add wave -noupdate -radix unsigned /top_tb/th/uut/must_flush
add wave -noupdate -radix unsigned /top_tb/th/uut/correct_address
add wave -noupdate -divider -height 20 {Restart Interface}
add wave -noupdate -radix unsigned /top_tb/th/uut/invalid_instruction
add wave -noupdate -radix unsigned /top_tb/th/uut/invalid_prediction
add wave -noupdate -radix unsigned /top_tb/th/uut/is_return_in
add wave -noupdate -radix unsigned /top_tb/th/uut/is_jumpl
add wave -noupdate -radix unsigned /top_tb/th/uut/old_PC
add wave -noupdate -divider -height 20 {Predictor Update Interface}
add wave -noupdate -radix unsigned /top_tb/th/uut/is_branch
add wave -noupdate -radix unsigned /top_tb/th/uut/pr_update.valid_jump
add wave -noupdate -radix unsigned /top_tb/th/uut/pr_update.jump_taken
add wave -noupdate -radix unsigned /top_tb/th/uut/pr_update.orig_pc
add wave -noupdate -radix unsigned /top_tb/th/uut/pr_update.jump_address
add wave -noupdate -divider Predictor
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/must_flush
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/is_branch
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/branch_resolved
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/new_entry
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/PC_Orig
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/Target_PC
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/is_Taken
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/is_return
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/is_jumpl
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/invalidate
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/old_PC
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/PC_in
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/taken_branch_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/next_PC_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/taken_branch_b
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/next_PC_b
add wave -noupdate -divider GSHARE
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/clk
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/rst_n
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/PC_in_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/PC_in_b
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/is_Taken_out_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/is_Taken_out_b
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/Wr_En
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/Orig_PC
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/GShare/is_Taken
add wave -noupdate -divider BTB
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/clk
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/rst_n
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/Wr_En
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/Orig_PC
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/Target_PC
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/invalidate
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/pc_invalid
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/PC_in_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/PC_in_b
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/Hit_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/Hit_b
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/next_PC_a
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/BTB/next_PC_b
add wave -noupdate /top_tb/th/uut/Predictor/BTB/masked_wr_en
add wave -noupdate -divider RAS
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/clk
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/rst_n
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/must_flush
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/is_branch
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/branch_resolved
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/Pop
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/Push
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/new_entry
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/PC_out
add wave -noupdate -radix unsigned /top_tb/th/uut/Predictor/RAS/is_empty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {260000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 211
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {155310 ps} {364690 ps}
