; =========================================================================
;                MINI BANK MANAGEMENT SYSTEM (EMU8086 ASSEMBLY)
; =========================================================================
; COAL 4th Semester Project
; Compatible with: EMU8086 Emulator
; =========================================================================

.MODEL SMALL
.STACK 100h

.DATA
    ; User Interface Strings
    msg_welcome1    DB "      ==========================================", 13, 10
                    DB "      *      WELCOME TO MINI BANK SYSTEM       *", 13, 10
                    DB "      ==========================================", 13, 10, "$"
                    
    msg_loading     DB "      Initializing system components...", 13, 10, "$"
    
    msg_welcome2    DB 13, 10, "      System Ready! Press any key to continue...$"
    
    msg_exit1       DB "      ==========================================", 13, 10
                    DB "      *   THANK YOU FOR USING MINI BANK SYSTEM  *", 13, 10
                    DB "      *          Have a Wonderful Day!         *", 13, 10
                    DB "      ==========================================", 13, 10, "$"
                    
    msg_menu_title  DB "  +--------------------------------------------+", 13, 10
                    DB "  |         MINI BANK MANAGEMENT SYSTEM        |", 13, 10
                    DB "  +--------------------------------------------+", 13, 10, "$"
    msg_menu_opts   DB "  1. Create Account", 13, 10
                    DB "  2. Deposit Money", 13, 10
                    DB "  3. Withdraw Money", 13, 10
                    DB "  4. Check Balance", 13, 10
                    DB "  5. View Account Details", 13, 10
                    DB "  6. Exit Program", 13, 10, "$"
    msg_menu_prompt DB "  Enter your choice (1-6): $"
    
    msg_invalid     DB 13, 10, "  [!] Invalid Choice! Try again.", 13, 10, "$"
    msg_pause       DB 13, 10, "  Press any key to return to main menu...$"
    msg_acct_prompt DB "  Enter 4-Digit Account Number: $"
    msg_pin_prompt  DB "  Enter 4-Digit PIN: $"
    msg_incorrect_pin DB 13, 10, "  [X] Incorrect PIN! Access Denied.", 13, 10, "$"
    msg_acct_not_found DB 13, 10, "  [X] Account Number Not Found!", 13, 10, "$"
    
    msg_create_title DB "  === CREATE NEW ACCOUNT ===", 13, 10, "$"
    msg_create_num   DB "  Enter New 4-Digit Account Number: $"
    msg_create_name  DB "  Enter Holder's Name (Max 14 chars): $"
    msg_create_pin   DB "  Enter New 4-Digit PIN: $"
    msg_create_dep   DB "  Enter Initial Deposit Amount ($): $"
    msg_create_success DB 13, 10, "  [V] Account Created Successfully!", 13, 10, "$"
    msg_db_full      DB 13, 10, "  [X] Error: Bank database is full (Max 3 accounts).", 13, 10, "$"
    
    msg_dep_title    DB "  === DEPOSIT MONEY ===", 13, 10, "$"
    msg_dep_amt      DB "  Enter Amount to Deposit ($): $"
    msg_dep_success  DB 13, 10, "  [V] Deposit Successful!", 13, 10, "$"
    
    msg_wd_title     DB "  === WITHDRAW MONEY ===", 13, 10, "$"
    msg_wd_amt       DB "  Enter Amount to Withdraw ($): $"
    msg_wd_success   DB 13, 10, "  [V] Withdrawal Successful!", 13, 10, "$"
    msg_wd_insufficient DB 13, 10, "  [X] Error: Insufficient Balance!", 13, 10, "$"
    
    msg_bal_title    DB "  === CHECK BALANCE ===", 13, 10, "$"
    msg_det_title    DB "  === ACCOUNT DETAILS ===", 13, 10, "$"
    msg_show_num     DB "  Account Number: $"
    msg_show_name    DB "  Account Holder: $"
    msg_show_bal     DB "  Current Balance: $"
    msg_status_label DB "  Account Status: Active", 13, 10, "$"
    msg_currency     DB " $"
    
    temp_num         DW 0
    temp_pin         DW 0
    temp_amount      DW 0
    curr_acct_idx    DB 0 
    
    ; Database Structures (Parallel Arrays for 3 Accounts)
    acc_active       DB 1, 1, 0
    acc_num          DW 1001, 1002, 0
    acc_pin          DW 1234, 5678, 0
    acc_balance      DW 5000, 3000, 0
    
    acc1_name        DB "Mustafa        $"
    acc2_name        DB "Ali            $"
    acc3_name        DB "Empty          $"
    
    acc_name_ptrs    DW OFFSET acc1_name, OFFSET acc2_name, OFFSET acc3_name

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    CALL WelcomeScreen

main_menu_loop:
    CALL ClearScreen
    
    MOV AH, 09h
    LEA DX, msg_menu_title
    INT 21h
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_menu_opts
    INT 21h
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_menu_prompt
    INT 21h
    
    MOV AH, 01h
    INT 21h
    PUSH AX          
    
    CALL PrintNewline
    POP AX           
    
    CMP AL, '1'
    JE opt_create
    CMP AL, '2'
    JE opt_deposit
    CMP AL, '3'
    JE opt_withdraw
    CMP AL, '4'
    JE opt_balance
    CMP AL, '5'
    JE opt_details
    CMP AL, '6'
    JE opt_exit
    
    MOV AH, 09h
    LEA DX, msg_invalid
    INT 21h
    CALL WaitKey
    JMP main_menu_loop
    
opt_create:
    CALL ClearScreen
    CALL CreateAccount
    JMP op_done
    
opt_deposit:
    CALL ClearScreen
    CALL DepositMoney
    JMP op_done
    
opt_withdraw:
    CALL ClearScreen
    CALL WithdrawMoney
    JMP op_done
    
opt_balance:
    CALL ClearScreen
    CALL CheckBalance
    JMP op_done
    
opt_details:
    CALL ClearScreen
    CALL ViewDetails
    JMP op_done
    
opt_exit:
    CALL ClearScreen
    MOV AH, 09h
    LEA DX, msg_exit1
    INT 21h
    CALL WaitKey
    
    MOV AH, 4Ch      
    INT 21h
    
op_done:
    MOV AH, 09h
    LEA DX, msg_pause
    INT 21h
    CALL WaitKey
    JMP main_menu_loop

MAIN ENDP


; =========================================================================
;                           CORE PROCEDURES
; =========================================================================

; -------------------------------------------------------------------------
; Procedure: WelcomeScreen
; Purpose: Displays the welcome screen and executes loading animation
; -------------------------------------------------------------------------
WelcomeScreen PROC
    CALL ClearScreen
    CALL PrintNewline
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_welcome1
    INT 21h
    
    CALL PrintNewline
    
    CALL PrintLoading
    
    MOV AH, 09h
    LEA DX, msg_welcome2
    INT 21h
    
    CALL WaitKey
    RET
WelcomeScreen ENDP


; -------------------------------------------------------------------------
; Procedure: PrintLoading
; Purpose: Renders interactive ASCII loading bar with delay loops
; -------------------------------------------------------------------------
PrintLoading PROC
    PUSH CX
    PUSH DX
    
    MOV AH, 09h
    LEA DX, msg_loading
    INT 21h
    
    MOV AH, 02h
    MOV DL, ' '
    INT 21h
    MOV DL, ' '
    INT 21h
    MOV DL, '['
    INT 21h
    
    MOV CX, 20
loading_loop:
    MOV DL, '='
    MOV AH, 02h
    INT 21h
    
    CALL Delay       
    LOOP loading_loop
    
    MOV DL, ']'
    MOV AH, 02h
    INT 21h
    
    CALL PrintNewline
    POP DX
    POP CX
    RET
PrintLoading ENDP


; -------------------------------------------------------------------------
; Procedure: CreateAccount
; Purpose: Registers a new account in the first available empty database slot
; -------------------------------------------------------------------------
CreateAccount PROC
    MOV AH, 09h
    LEA DX, msg_create_title
    INT 21h
    CALL PrintNewline
    
    MOV SI, 0
find_empty_loop:
    CMP SI, 3
    JE db_full
    
    MOV AL, acc_active[SI]
    CMP AL, 0
    JE empty_slot_found
    
    INC SI
    JMP find_empty_loop
    
db_full:
    MOV AH, 09h
    LEA DX, msg_db_full
    INT 21h
    RET
    
empty_slot_found:
    ; Convert byte index SI to word index DI (DI = SI * 2)
    MOV DI, SI
    SHL DI, 1
    
    MOV AH, 09h
    LEA DX, msg_create_num
    INT 21h
    CALL ReadNum
    MOV acc_num[DI], AX
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_create_name
    INT 21h
    MOV DI, acc_name_ptrs[DI] 
    CALL ReadString
    
    MOV DI, SI
    SHL DI, 1
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_create_pin
    INT 21h
    CALL ReadPIN
    MOV acc_pin[DI], AX
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_create_dep
    INT 21h
    CALL ReadNum
    MOV acc_balance[DI], AX
    
    MOV acc_active[SI], 1
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_create_success
    INT 21h
    RET
CreateAccount ENDP


; -------------------------------------------------------------------------
; Procedure: DepositMoney
; Purpose: Authenticates access, adds deposit amount to account balance
; -------------------------------------------------------------------------
DepositMoney PROC
    MOV AH, 09h
    LEA DX, msg_dep_title
    INT 21h
    
    CALL VerifyAccess
    CMP AX, 0
    JE dep_fail      
    
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_dep_amt
    INT 21h
    CALL ReadNum
    
    ADD acc_balance[DI], AX
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_dep_success
    INT 21h
    
    MOV AH, 09h
    LEA DX, msg_show_bal
    INT 21h
    MOV AX, acc_balance[DI]
    CALL PrintNum
    CALL PrintNewline
    
dep_fail:
    RET
DepositMoney ENDP


; -------------------------------------------------------------------------
; Procedure: WithdrawMoney
; Purpose: Authenticates access, processes withdrawal if balance is sufficient
; -------------------------------------------------------------------------
WithdrawMoney PROC
    MOV AH, 09h
    LEA DX, msg_wd_title
    INT 21h
    
    CALL VerifyAccess
    CMP AX, 0
    JE wd_fail
    
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_wd_amt
    INT 21h
    CALL ReadNum
    MOV temp_amount, AX
    
    MOV AX, acc_balance[DI]
    CMP AX, temp_amount
    JB insufficient_bal
    
    SUB AX, temp_amount
    MOV acc_balance[DI], AX
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_wd_success
    INT 21h
    
    MOV AH, 09h
    LEA DX, msg_show_bal
    INT 21h
    MOV AX, acc_balance[DI]
    CALL PrintNum
    CALL PrintNewline
    JMP wd_fail
    
insufficient_bal:
    MOV AH, 09h
    LEA DX, msg_wd_insufficient
    INT 21h
    
wd_fail:
    RET
WithdrawMoney ENDP


; -------------------------------------------------------------------------
; Procedure: CheckBalance
; Purpose: Authenticates access, displays current account balance
; -------------------------------------------------------------------------
CheckBalance PROC
    MOV AH, 09h
    LEA DX, msg_bal_title
    INT 21h
    
    CALL VerifyAccess
    CMP AX, 0
    JE bal_fail
    
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_show_name
    INT 21h
    MOV DX, acc_name_ptrs[DI]
    MOV AH, 09h
    INT 21h
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_show_bal
    INT 21h
    MOV AX, acc_balance[DI]
    CALL PrintNum
    CALL PrintNewline
    
bal_fail:
    RET
CheckBalance ENDP


; -------------------------------------------------------------------------
; Procedure: ViewDetails
; Purpose: Authenticates access, displays complete profile metadata card
; -------------------------------------------------------------------------
ViewDetails PROC
    MOV AH, 09h
    LEA DX, msg_det_title
    INT 21h
    
    CALL VerifyAccess
    CMP AX, 0
    JE det_fail
    
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    MOV AH, 02h
    MOV DL, ' '
    INT 21h
    MOV DL, '-'
    MOV CX, 30
det_border:
    INT 21h
    LOOP det_border
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_show_num
    INT 21h
    MOV AX, acc_num[DI]
    CALL PrintNum
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_show_name
    INT 21h
    MOV DX, acc_name_ptrs[DI]
    MOV AH, 09h
    INT 21h
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_show_bal
    INT 21h
    MOV AX, acc_balance[DI]
    CALL PrintNum
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_status_label
    INT 21h
    
    MOV AH, 02h
    MOV DL, ' '
    INT 21h
    MOV DL, '-'
    MOV CX, 30
det_border2:
    INT 21h
    LOOP det_border2
    CALL PrintNewline
    
det_fail:
    RET
ViewDetails ENDP


; =========================================================================
;                          HELPER UTILITY PROCEDURES
; =========================================================================

; -------------------------------------------------------------------------
; Procedure: VerifyAccess
; Purpose: Prompts for account ID, matches index, and verifies masked PIN
; Returns: AX = 1 (Access Granted), AX = 0 (Access Denied)
; -------------------------------------------------------------------------
VerifyAccess PROC
    CALL PrintNewline
    MOV AH, 09h
    LEA DX, msg_acct_prompt
    INT 21h
    
    CALL ReadNum     
    MOV temp_num, AX
    
    MOV SI, 0        
search_loop:
    CMP SI, 3
    JE not_found
    
    MOV AL, acc_active[SI]
    CMP AL, 1
    JNE next_slot
    
    MOV DI, SI
    SHL DI, 1
    
    MOV AX, acc_num[DI]
    CMP AX, temp_num
    JE found_acct
    
next_slot:
    INC SI
    JMP search_loop
    
not_found:
    MOV AH, 09h
    LEA DX, msg_acct_not_found
    INT 21h
    MOV AX, 0        
    RET
    
found_acct:
    CALL PrintNewline
    MOV AH, 09h
    LEA DX, msg_pin_prompt
    INT 21h
    
    CALL ReadPIN     
    MOV temp_pin, AX
    
    MOV AX, acc_pin[DI]
    CMP AX, temp_pin
    JE pin_correct
    
    MOV AH, 09h
    LEA DX, msg_incorrect_pin
    INT 21h
    MOV AX, 0        
    RET
    
pin_correct:
    MOV AX, SI
    MOV curr_acct_idx, AL
    MOV AX, 1        
    RET
VerifyAccess ENDP


; -------------------------------------------------------------------------
; Procedure: ClearScreen
; Purpose: Clears console using standard BIOS Standard Mode 3 Color Text
; -------------------------------------------------------------------------
ClearScreen PROC
    PUSH AX
    MOV AH, 00h
    MOV AL, 03h      
    INT 10h          
    POP AX
    RET
ClearScreen ENDP


; -------------------------------------------------------------------------
; Procedure: PrintNewline
; Purpose: Prints CR (Carriage Return) and LF (Line Feed) characters
; -------------------------------------------------------------------------
PrintNewline PROC
    PUSH AX
    PUSH DX
    MOV AH, 02h
    MOV DL, 0Dh      
    INT 21h
    MOV DL, 0Ah      
    INT 21h
    POP DX
    POP AX
    RET
PrintNewline ENDP


; -------------------------------------------------------------------------
; Procedure: WaitKey
; Purpose: Pauses execution until a keyboard key is pressed
; -------------------------------------------------------------------------
WaitKey PROC
    PUSH AX
    MOV AH, 00h      
    INT 16h          
    POP AX
    RET
WaitKey ENDP


; -------------------------------------------------------------------------
; Procedure: Delay
; Purpose: Visual timing clock delay loop for loading indicators
; -------------------------------------------------------------------------
Delay PROC
    PUSH CX
    PUSH DX
    MOV CX, 0BFh     
d_loop1:
    MOV DX, 05FFh    
d_loop2:
    DEC DX
    JNZ d_loop2
    LOOP d_loop1
    POP DX
    POP CX
    RET
Delay ENDP


; -------------------------------------------------------------------------
; Procedure: ReadNum
; Purpose: Reads a sequence of numeric digits and parses to 16-bit binary
; Returns: AX = parsed integer
; -------------------------------------------------------------------------
ReadNum PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 0        
rn_loop:
    MOV AH, 01h      
    INT 21h
    
    CMP AL, 0Dh      
    JE rn_done
    
    CMP AL, '0'
    JB rn_loop
    CMP AL, '9'
    JA rn_loop
    
    SUB AL, '0'      
    MOV AH, 0
    PUSH AX          
    
    MOV AX, BX
    MOV CX, 10
    MUL CX           
    POP DX           
    ADD AX, DX       
    MOV BX, AX       
    JMP rn_loop
    
rn_done:
    MOV AX, BX       
    POP DX
    POP CX
    POP BX
    RET
ReadNum ENDP


; -------------------------------------------------------------------------
; Procedure: PrintNum
; Purpose: Splits a 16-bit binary integer to base-10 digits and outputs
; Input: AX = number to print
; -------------------------------------------------------------------------
PrintNum PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CMP AX, 0
    JNE pn_start
    
    MOV AH, 02h
    MOV DL, '0'
    INT 21h
    JMP pn_done
    
pn_start:
    MOV CX, 0        
    MOV BX, 10       
    
pn_loop:
    MOV DX, 0        
    DIV BX           
    PUSH DX          
    INC CX
    CMP AX, 0
    JNE pn_loop
    
pn_print:
    POP DX
    ADD DL, '0'      
    MOV AH, 02h      
    INT 21h
    LOOP pn_print
    
pn_done:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNum ENDP


; -------------------------------------------------------------------------
; Procedure: ReadPIN
; Purpose: Captures exactly 4 characters and outputs masked asterisks '*'
; Returns: AX = parsed integer PIN
; -------------------------------------------------------------------------
ReadPIN PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 0        
    MOV CX, 4        
rp_loop:
    MOV AH, 08h      
    INT 21h
    
    CMP AL, '0'
    JB rp_loop
    CMP AL, '9'
    JA rp_loop
    
    PUSH AX
    MOV AH, 02h
    MOV DL, '*'
    INT 21h
    POP AX
    
    SUB AL, '0'
    MOV AH, 0
    PUSH AX          
    
    MOV AX, BX
    MOV DX, 10
    MUL DX
    POP DX           
    ADD AX, DX       
    MOV BX, AX       
    LOOP rp_loop
    
    MOV AX, BX       
    POP DX
    POP CX
    POP BX
    RET
ReadPIN ENDP


; -------------------------------------------------------------------------
; Procedure: ReadString
; Purpose: Captures text string input and space-pads to maintain UI bounds
; Input: DI = Buffer Destination Address
; -------------------------------------------------------------------------
ReadString PROC
    PUSH AX
    PUSH CX
    PUSH DI
    
    MOV CX, 0        
rs_char_loop:
    MOV AH, 01h      
    INT 21h
    
    CMP AL, 0Dh      
    JE rs_fill_spaces
    
    MOV [DI], AL     
    INC DI
    INC CX
    CMP CX, 14       
    JE rs_fill_spaces
    JMP rs_char_loop
    
rs_fill_spaces:
    CMP CX, 14
    JAE rs_terminate
    MOV BYTE PTR [DI], ' '
    INC DI
    INC CX
    JMP rs_fill_spaces
    
rs_terminate:
    MOV BYTE PTR [DI], '$' 
    POP DI
    POP CX
    POP AX
    RET
ReadString ENDP

END MAIN
