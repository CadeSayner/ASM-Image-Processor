.data
    # Input and output file locations (Change these)
    input_file_location: .asciiz "C:\Users\User\OneDrive\Desktop\Arch_Assignment\sample_images\house_64_in_ascii_lf.ppm"
    output_file_location: .asciiz "C:\Users\User\OneDrive\Desktop\output.ppm"


    header: .asciiz "P2\n#    \n64 64\n255\n"
    buffer: .space 60000
    output_buffer: .space 60000
    exception: .asciiz "File not found exception"
    output_average_before_message: .asciiz "Average pixel value of the original image:\n"
    output_average_after_message: .asciiz "\nAverage pixel value of new image:\n"

.text
.globl main 

main:
    li  $v0, 13     # System call to open file, $v0 set to file descriptor
                # $v0 negative if failed to open file
    la  $a0, input_file_location   # Load file to read, $a0 set to address of string
                # containing file name
    li  $a1, 0      # Set read-only flag
    li  $a2, 0      # Set mode
    syscall

    add $s0, $v0, $zero # Save file descriptor in $v0 to new register $s0
                # because $v0 will be used in other system calls
    blt $v0, 0, error # Go to handler if failed to open file

    li  $v0, 13     # System call to open file, $v0 set to file descriptor
                # $v0 negative if failed to open file
    la  $a0, output_file_location   # Load file to write, $a0 set to address of string
                # containing file name
    li  $a1, 1     # Set write-only flag
    li  $a2, 0      # Set mode
    syscall

    add $s1, $v0, $zero # Save file descriptor in $v0 to new register $s0
                # because $v0 will be used in other system calls
    blt $v0, 0, error # Go to exception handler if failed to open file

    # write headers to output_buffer
    li $t7, 0

write_headers_to_output_buffer:
    lb $t2, header($t7)
    beq $t2, 0, read
    sb $t2, output_buffer($t7)
    addi $t7, $t7, 1
    j write_headers_to_output_buffer


read:
    li  $v0, 14     # System call to read file
    add $a0, $s0, $zero # Load file descriptor to $a0
    la  $a1, buffer # Set $a1 to address of input buffer where
                # text will be loaded to
    li  $a2 60000   # Set $a2 to maximum number of characters to read
    syscall

    

    #after read, $v0 will have number of bytes read
    #set last byte to null
    la  $a0, buffer
    add $a0, $a0, $v0   #address of byte after file data
    sb  $zero, 0($a0)
    move $s2, $v0 # $s2 holds the number of the last byte read

    li $v0, 16 # Close the file we are done reading
    syscall

    # Write the 3 character comment to the output buffer
    la $t0, buffer
    la $t2, output_buffer
    lb $t1, 5($t0)
    sb $t1, 5($t2)
    lb $t1, 6($t0)
    sb $t1, 6($t2)
    lb $t1, 7($t0)
    sb $t1, 7($t2)


    li $t0, 19 # Start of first number (index for read buffer)
    li $t5, 19 # Output buffer index
    li $t1, 10 # multiplication factor
    li $t4, 0 # t4 stores current integer value 
    li $s3, 0


loop:
    li $t4, 0 # t4 stores current integer value 
    jal get_next_integer
    move $s4, $t4
    addi $t0, $t0, 1
    li $t4, 0
    jal get_next_integer
    move $s5, $t4
    addi $t0, $t0, 1
    li $t4, 0
    jal get_next_integer
    move $s6, $t4

    # Now add all three uo
    add $s4, $s4, $s5
    add $s4, $s4, $s6
    li $s8, 3
    div $s4, $s8
    mflo $t4


    # If here succesfully got the average of three pixel values saved in $t4
    li $t2, 0 # To ensure there is a null byte to mark the beginning of stack
    sb $t2, 0($sp) 
    # addi $sp, $sp, -1

    jal integer_to_ascii
    
    # Now stack has the desired integer where stack is located and can be written to the output buffer 
    jal write_stack_to_output_buffer

    addi $t0, $t0, 1 # To ensure we start at a normal number again
    j loop



write_stack_to_output_buffer: 
    lb $s4, 0($sp)
    beq $s4, 0, write_stack_complete
    sb $s4, output_buffer($t5)
    addi $sp, $sp, 1 # Will increment stack back to starting address
    addi $t5, $t5, 1
    j write_stack_to_output_buffer

write_stack_complete:
    sb $t1, output_buffer($t5)
    addi $t5, $t5, 1
    j $ra

integer_to_ascii:
    # This code loads the correct ascii for the number in $t4 and places it into stack memory for later reading
    div $t4, $t1 # divide t4 by 10
    mflo $t4
    mfhi $t6 # has the remainder
    addi $sp, -1
    addi $t6, $t6, 48
    sb $t6, 0($sp) # add the ascii value onto the stack
    beq $t4, 0, integer_to_ascii_return
    addi $t2, $t2, 1
    j integer_to_ascii

integer_to_ascii_return:
    j $ra # Go back to callee

get_next_integer:
    lb $t2, buffer($t0)
    beq $t2, 10, get_next_integer_completed
    beq $t2, 0, main_loop_done
    addi $t2, $t2, -48
    mul $t4, $t4, $t1 # Multiply what is already there by 10 and then add whatever extra digit we have 
    add $t4, $t4, $t2
    addi $t0, $t0, 1
    j get_next_integer

get_next_integer_completed:
    # Before we can change the value add to the old average counter
    add $s7, $s7, $t4
    add $s8, $s8, $t4
    j $ra # Go back to the place in the main loop


write_to_file:
    li   $v0, 15       # system call for write to file
    move $a0, $s1      # file descriptor 
    la   $a1, output_buffer   # address of buffer from which to write
    move  $a2, $t5    # hardcoded buffer length
    syscall            # write to file

    # Close the file now 
    li $v0, 16
    syscall # a0 already has the file descriptor for the output file here, so can syscall immediately

    j exit # Exit after successfully written to the output file

error:
    li $v0, 4   
    la $a0, exception # Output the exception string to the console
    syscall

main_loop_done:
    j write_to_file # Done, now write to the output file

exit:
    li $v0, 10
    syscall