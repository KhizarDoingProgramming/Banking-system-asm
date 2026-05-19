; =========================================================================
;                MINI BANK MANAGEMENT SYSTEM (EMU8086 ASSEMBLY)
; =========================================================================
; COAL 4th Semester Project
; Compatible with: EMU8086 Emulator
; Features: Account Creation, Deposit, Withdrawal, PIN Security, 
;           Balance Inquiry, Details View, and ASCII Interface.
; =========================================================================

.MODEL SMALL
.STACK 100h

.DATA
    ; =========================================================================
    ;                           USER INTERFACE STRINGS
    ; =========================================================================
    msg_welcome1    DB "      ==========================================", 13, 10
                    DB "      *      WELCOME TO MINI BANK SYSTEM       *", 13, 10
                    DB "      ==========================================", 13, 10, "$"
                    
    msg_loading     DB "      Initializing system components...", 13, 10, "$"
    
    msg_welcome2    DB 13, 10, "      System Ready! Press any key to continue...$"
    
    msg_exit1       DB "      ==========================================", 13, 10
                    DB "      *   THANK YOU FOR USING MINI BANK SYSTEM  *", 13, 10
                    DB "      *          Have a Wonderful Day!         *", 13, 10
                    DB "      ==========================================", 13, 10, "$"
                    
    ; Menu Strings
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
    
    ; General Prompts & Messages
    msg_invalid     DB 13, 10, "  [!] Invalid Choice! Try again.", 13, 10, "$"
    msg_pause       DB 13, 10, "  Press any key to return to main menu...$"
    msg_acct_prompt DB "  Enter 4-Digit Account Number: $"
    msg_pin_prompt  DB "  Enter 4-Digit PIN: $"
    msg_incorrect_pin DB 13, 10, "  [X] Incorrect PIN! Access Denied.", 13, 10, "$"
    msg_acct_not_found DB 13, 10, "  [X] Account Number Not Found!", 13, 10, "$"
    
    ; Create Account Strings
    msg_create_title DB "  === CREATE NEW ACCOUNT ===", 13, 10, "$"
    msg_create_num   DB "  Enter New 4-Digit Account Number: $"
    msg_create_name  DB "  Enter Holder's Name (Max 14 chars): $"
    msg_create_pin   DB "  Enter New 4-Digit PIN: $"
    msg_create_dep   DB "  Enter Initial Deposit Amount ($): $"
    msg_create_success DB 13, 10, "  [V] Account Created Successfully!", 13, 10, "$"
    msg_db_full      DB 13, 10, "  [X] Error: Bank database is full (Max 3 accounts).", 13, 10, "$"
    
    ; Deposit Strings
    msg_dep_title    DB "  === DEPOSIT MONEY ===", 13, 10, "$"
    msg_dep_amt      DB "  Enter Amount to Deposit ($): $"
    msg_dep_success  DB 13, 10, "  [V] Deposit Successful!", 13, 10, "$"
    
    ; Withdrawal Strings
    msg_wd_title     DB "  === WITHDRAW MONEY ===", 13, 10, "$"
    msg_wd_amt       DB "  Enter Amount to Withdraw ($): $"
    msg_wd_success   DB 13, 10, "  [V] Withdrawal Successful!", 13, 10, "$"
    msg_wd_insufficient DB 13, 10, "  [X] Error: Insufficient Balance!", 13, 10, "$"
    
    ; Balance / Details Strings
    msg_bal_title    DB "  === CHECK BALANCE ===", 13, 10, "$"
    msg_det_title    DB "  === ACCOUNT DETAILS ===", 13, 10, "$"
    msg_show_num     DB "  Account Number: $"
    msg_show_name    DB "  Account Holder: $"
    msg_show_bal     DB "  Current Balance: $"
    msg_status_label DB "  Account Status: Active", 13, 10, "$"
    msg_currency     DB " $"
    
    ; Temporary Variables for Computations
    temp_num         DW 0
    temp_pin         DW 0
    temp_amount      DW 0
    curr_acct_idx    DB 0 ; Stores currently accessed account byte index (0, 1, or 2)
    
    ; =========================================================================
    ;                           DATABASE SEGMENT
    ; =========================================================================
    ; Parallel Arrays for storing 3 Accounts.
    ; Accounts 1 & 2 are pre-populated for testing. Account 3 is empty.
    acc_active       DB 1, 1, 0
    acc_num          DW 1001, 1002, 0
    acc_pin          DW 1234, 5678, 0
    acc_balance      DW 5000, 3000, 0
    
    ; Name buffers (fixed 15 bytes each, space-padded, ending with '$')
    acc1_name        DB "Mustafa        $"
    acc2_name        DB "Ali            $"
    acc3_name        DB "Empty          $"
    
    ; Pointer array for dynamic string addressing
    acc_name_ptrs    DW OFFSET acc1_name, OFFSET acc2_name, OFFSET acc3_name

.CODE
MAIN PROC
    ; Initialize the Data Segment
    MOV AX, @DATA
    MOV DS, AX
    
    ; Show the interactive welcome screen and loading bar
    CALL WelcomeScreen

main_menu_loop:
    ; Clear screen for redrawing the main menu
    CALL ClearScreen
    
    ; Draw main menu header
    MOV AH, 09h
    LEA DX, msg_menu_title
    INT 21h
    
    CALL PrintNewline
    
    ; Draw menu options
    MOV AH, 09h
    LEA DX, msg_menu_opts
    INT 21h
    
    CALL PrintNewline
    
    ; Prompt for choice
    MOV AH, 09h
    LEA DX, msg_menu_prompt
    INT 21h
    
    ; Read choice from keyboard
    MOV AH, 01h
    INT 21h
    PUSH AX          ; Save choice in stack
    
    CALL PrintNewline
    POP AX           ; Restore choice
    
    ; Route selection to appropriate procedure
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
    
    ; If invalid selection
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
    ; Exit procedure: draw exit screen, wait for key, terminate
    CALL ClearScreen
    MOV AH, 09h
    LEA DX, msg_exit1
    INT 21h
    CALL WaitKey
    
    MOV AH, 4Ch      ; Standard DOS termination interrupt
    INT 21h
    
op_done:
    ; Pause screen before returning to the main menu
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
; Purpose: Displays the welcome screen and executes a loading animation
; -------------------------------------------------------------------------
WelcomeScreen PROC
    CALL ClearScreen
    CALL PrintNewline
    CALL PrintNewline
    
    ; Print welcome message banner
    MOV AH, 09h
    LEA DX, msg_welcome1
    INT 21h
    
    CALL PrintNewline
    
    ; Print loading animation
    CALL PrintLoading
    
    ; Prompt to continue
    MOV AH, 09h
    LEA DX, msg_welcome2
    INT 21h
    
    CALL WaitKey
    RET
WelcomeScreen ENDP


; -------------------------------------------------------------------------
; Procedure: PrintLoading
; Purpose: Renders an interactive ASCII loading bar with delays
; -------------------------------------------------------------------------
PrintLoading PROC
    PUSH CX
    PUSH DX
    
    ; Print status
    MOV AH, 09h
    LEA DX, msg_loading
    INT 21h
    
    ; Print progress bar opening bracket
    MOV AH, 02h
    MOV DL, ' '
    INT 21h
    MOV DL, ' '
    INT 21h
    MOV DL, '['
    INT 21h
    
    ; Loop to draw 20 loader bars
    MOV CX, 20
loading_loop:
    MOV DL, '='
    MOV AH, 02h
    INT 21h
    
    CALL Delay       ; Add a visual time delay
    LOOP loading_loop
    
    ; Print closing bracket
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
; Purpose: Scans for an inactive slot, registers a new account
; -------------------------------------------------------------------------
CreateAccount PROC
    ; Title
    MOV AH, 09h
    LEA DX, msg_create_title
    INT 21h
    CALL PrintNewline
    
    ; Scan parallel active flags array for 0 (inactive status)
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
    
    ; Prompt and read Account Number
    MOV AH, 09h
    LEA DX, msg_create_num
    INT 21h
    CALL ReadNum
    MOV acc_num[DI], AX
    
    CALL PrintNewline
    
    ; Prompt and read Name
    MOV AH, 09h
    LEA DX, msg_create_name
    INT 21h
    MOV DI, acc_name_ptrs[DI] ; Retrieve correct string buffer address
    CALL ReadString
    
    ; Recalculate word index DI since it was modified in ReadString
    MOV DI, SI
    SHL DI, 1
    
    CALL PrintNewline
    
    ; Prompt and read 4-Digit PIN (Masked entry)
    MOV AH, 09h
    LEA DX, msg_create_pin
    INT 21h
    CALL ReadPIN
    MOV acc_pin[DI], AX
    
    CALL PrintNewline
    
    ; Prompt and read Initial Deposit
    MOV AH, 09h
    LEA DX, msg_create_dep
    INT 21h
    CALL ReadNum
    MOV acc_balance[DI], AX
    
    ; Set active flag to 1
    MOV acc_active[SI], 1
    
    CALL PrintNewline
    
    ; Print Success Message
    MOV AH, 09h
    LEA DX, msg_create_success
    INT 21h
    RET
CreateAccount ENDP


; -------------------------------------------------------------------------
; Procedure: DepositMoney
; Purpose: Authenticates user, deposits money and updates balance
; -------------------------------------------------------------------------
DepositMoney PROC
    MOV AH, 09h
    LEA DX, msg_dep_title
    INT 21h
    
    ; Authenticate
    CALL VerifyAccess
    CMP AX, 0
    JE dep_fail      ; Return if authentication failed
    
    ; Get word index of current account
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    ; Read Deposit Amount
    MOV AH, 09h
    LEA DX, msg_dep_amt
    INT 21h
    CALL ReadNum
    
    ; Update Balance
    ADD acc_balance[DI], AX
    
    CALL PrintNewline
    
    ; Success Message
    MOV AH, 09h
    LEA DX, msg_dep_success
    INT 21h
    
    ; Display Updated Balance
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
; Purpose: Authenticates user, withdraws money if balance is sufficient
; -------------------------------------------------------------------------
WithdrawMoney PROC
    MOV AH, 09h
    LEA DX, msg_wd_title
    INT 21h
    
    ; Authenticate
    CALL VerifyAccess
    CMP AX, 0
    JE wd_fail
    
    ; Get word index of current account
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    ; Read Withdrawal Amount
    MOV AH, 09h
    LEA DX, msg_wd_amt
    INT 21h
    CALL ReadNum
    MOV temp_amount, AX
    
    ; Check if enough balance exists
    MOV AX, acc_balance[DI]
    CMP AX, temp_amount
    JB insufficient_bal
    
    ; Subtract and show success
    SUB AX, temp_amount
    MOV acc_balance[DI], AX
    
    CALL PrintNewline
    
    MOV AH, 09h
    LEA DX, msg_wd_success
    INT 21h
    
    ; Display Updated Balance
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
; Purpose: Authenticates and displays current balance
; -------------------------------------------------------------------------
CheckBalance PROC
    MOV AH, 09h
    LEA DX, msg_bal_title
    INT 21h
    
    CALL VerifyAccess
    CMP AX, 0
    JE bal_fail
    
    ; Get indices
    MOV AL, curr_acct_idx
    MOV AH, 0
    MOV DI, AX
    SHL DI, 1
    
    CALL PrintNewline
    
    ; Display name
    MOV AH, 09h
    LEA DX, msg_show_name
    INT 21h
    MOV DX, acc_name_ptrs[DI]
    MOV AH, 09h
    INT 21h
    CALL PrintNewline
    
    ; Display balance
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
; Purpose: Displays complete profile information of authenticated account
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
    
    ; Draw visual info container card
    MOV AH, 02h
    MOV DL, ' '
    INT 21h
    MOV DL, '-'
    MOV CX, 30
det_border:
    INT 21h
    LOOP det_border
    CALL PrintNewline
    
    ; Show Account Number
    MOV AH, 09h
    LEA DX, msg_show_num
    INT 21h
    MOV AX, acc_num[DI]
    CALL PrintNum
    CALL PrintNewline
    
    ; Show Account Holder Name
    MOV AH, 09h
    LEA DX, msg_show_name
    INT 21h
    MOV DX, acc_name_ptrs[DI]
    MOV AH, 09h
    INT 21h
    CALL PrintNewline
    
    ; Show Current Balance
    MOV AH, 09h
    LEA DX, msg_show_bal
    INT 21h
    MOV AX, acc_balance[DI]
    CALL PrintNum
    CALL PrintNewline
    
    ; Show Status
    MOV AH, 09h
    LEA DX, msg_status_label
    INT 21h
    
    ; Draw bottom card border
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
; Purpose: Prompts for Account ID, finds match, verifies masked PIN.
; Returns: AX = 1 (Successful), AX = 0 (Failure)
; -------------------------------------------------------------------------
VerifyAccess PROC
    CALL PrintNewline
    MOV AH, 09h
    LEA DX, msg_acct_prompt
    INT 21h
    
    CALL ReadNum     ; Read account number in AX
    MOV temp_num, AX
    
    MOV SI, 0        ; Scanner loop variable
search_loop:
    CMP SI, 3
    JE not_found
    
    ; Verify that the index slot is active
    MOV AL, acc_active[SI]
    CMP AL, 1
    JNE next_slot
    
    ; Get word index
    MOV DI, SI
    SHL DI, 1
    
    ; Compare entered ID with database ID
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
    MOV AX, 0        ; Return authentication failure code
    RET
    
found_acct:
    ; Account exists! Now prompt for 4-Digit Security PIN
    CALL PrintNewline
    MOV AH, 09h
    LEA DX, msg_pin_prompt
    INT 21h
    
    CALL ReadPIN     ; Reads and masks security PIN, returns in AX
    MOV temp_pin, AX
    
    ; Verify against database PIN
    MOV AX, acc_pin[DI]
    CMP AX, temp_pin
    JE pin_correct
    
    ; Incorrect PIN branch
    MOV AH, 09h
    LEA DX, msg_incorrect_pin
    INT 21h
    MOV AX, 0        ; Return authentication failure code
    RET
    
pin_correct:
    ; Write matched byte index SI to curr_acct_idx
    MOV AX, SI
    MOV curr_acct_idx, AL
    MOV AX, 1        ; Return authentication success code
    RET
VerifyAccess ENDP


; -------------------------------------------------------------------------
; Procedure: ClearScreen
; Purpose: Resets console using standard BIOS Mode 3 (80x25 Color Text)
; -------------------------------------------------------------------------
ClearScreen PROC
    PUSH AX
    MOV AH, 00h
    MOV AL, 03h      ; Video standard Mode 3
    INT 10h          ; Trigger BIOS video interrupt
    POP AX
    RET
ClearScreen ENDP


; -------------------------------------------------------------------------
; Procedure: PrintNewline
; Purpose: Outputs Carriage Return (CR) and Line Feed (LF) to command line
; -------------------------------------------------------------------------
PrintNewline PROC
    PUSH AX
    PUSH DX
    MOV AH, 02h
    MOV DL, 0Dh      ; Carriage Return
    INT 21h
    MOV DL, 0Ah      ; Line Feed
    INT 21h
    POP DX
    POP AX
    RET
PrintNewline ENDP


; -------------------------------------------------------------------------
; Procedure: WaitKey
; Purpose: Freezes execution using BIOS keyboard driver until key is typed
; -------------------------------------------------------------------------
WaitKey PROC
    PUSH AX
    MOV AH, 00h      ; Read keyboard character (No echo)
    INT 16h          ; Trigger BIOS keystroke driver
    POP AX
    RET
WaitKey ENDP


; -------------------------------------------------------------------------
; Procedure: Delay
; Purpose: Creates customizable visual execution delays for loading effect
; -------------------------------------------------------------------------
Delay PROC
    PUSH CX
    PUSH DX
    MOV CX, 0BFh     ; Outer nested counter loop (Tweak for speed)
d_loop1:
    MOV DX, 05FFh    ; Inner nested counter loop
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
; Purpose: Reads a decimal sequence from terminal and outputs 16-bit value
; Returns: AX = Unsigned 16-bit integer
; -------------------------------------------------------------------------
ReadNum PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 0        ; Empty accumulator register
rn_loop:
    MOV AH, 01h      ; Read character input with screen echo
    INT 21h
    
    CMP AL, 0Dh      ; Return immediately if Enter key is pressed
    JE rn_done
    
    ; Filter input: Accept digits '0'-'9' only
    CMP AL, '0'
    JB rn_loop
    CMP AL, '9'
    JA rn_loop
    
    SUB AL, '0'      ; Decode character to absolute numeric integer
    MOV AH, 0
    PUSH AX          ; Temporarily store digit
    
    MOV AX, BX
    MOV CX, 10
    MUL CX           ; AX = Current accumulated * 10
    POP DX           ; Pop the stored digit
    ADD AX, DX       ; Add digit to calculation
    MOV BX, AX       ; Move updated product back to BX
    JMP rn_loop
    
rn_done:
    MOV AX, BX       ; Store result inside output register AX
    POP DX
    POP CX
    POP BX
    RET
ReadNum ENDP


; -------------------------------------------------------------------------
; Procedure: PrintNum
; Purpose: Deconstructs 16-bit integer and prints base-10 layout to screen
; Input: AX = 16-bit integer to display
; -------------------------------------------------------------------------
PrintNum PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    CMP AX, 0
    JNE pn_start
    
    ; Output simple '0' character and return if zero
    MOV AH, 02h
    MOV DL, '0'
    INT 21h
    JMP pn_done
    
pn_start:
    MOV CX, 0        ; Counter for digits on stack
    MOV BX, 10       ; Base-10 divider
    
pn_loop:
    MOV DX, 0        ; Zero extension
    DIV BX           ; Divides DX:AX by 10. AX = Quotient, DX = Remainder (digit)
    PUSH DX          ; Pushes digits to stack
    INC CX
    CMP AX, 0
    JNE pn_loop
    
pn_print:
    POP DX
    ADD DL, '0'      ; Re-encode digit to ASCII standard
    MOV AH, 02h      ; Print character
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
; Purpose: Captures 4-Digit character sequence and echoes asterisk character
; Returns: AX = 16-bit integer of security code
; -------------------------------------------------------------------------
ReadPIN PROC
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 0        ; Empty accumulator
    MOV CX, 4        ; Set static limit count of exactly 4 digits
rp_loop:
    MOV AH, 08h      ; DOS read key without echoing to screen
    INT 21h
    
    ; Filter input: Accept digits '0'-'9' only
    CMP AL, '0'
    JB rp_loop
    CMP AL, '9'
    JA rp_loop
    
    ; Output asterisk symbol '*' to mask entry
    PUSH AX
    MOV AH, 02h
    MOV DL, '*'
    INT 21h
    POP AX
    
    ; Math operation: Accumulator = Accumulator * 10 + EnteredDigit
    SUB AL, '0'
    MOV AH, 0
    PUSH AX          ; Save digit
    
    MOV AX, BX
    MOV DX, 10
    MUL DX
    POP DX           ; Retrieve digit in DX
    ADD AX, DX       ; AX = AX * 10 + digit
    MOV BX, AX       ; Store accumulator back to BX
    LOOP rp_loop
    
    MOV AX, BX       ; Return final security code inside AX
    POP DX
    POP CX
    POP BX
    RET
ReadPIN ENDP


; -------------------------------------------------------------------------
; Procedure: ReadString
; Purpose: Safely captures string input, pads with space to exact buffer width
; Input: DI = Buffer Destination address
; -------------------------------------------------------------------------
ReadString PROC
    PUSH AX
    PUSH CX
    PUSH DI
    
    MOV CX, 0        ; Characters captured counter
rs_char_loop:
    MOV AH, 01h      ; Standard DOS read keyboard with echo
    INT 21h
    
    CMP AL, 0Dh      ; Break if Carriage Return (Enter) is pressed
    JE rs_fill_spaces
    
    MOV [DI], AL     ; Save character inside buffer
    INC DI
    INC CX
    CMP CX, 14       ; Enforce safe limit boundary of max 14 characters
    JE rs_fill_spaces
    JMP rs_char_loop
    
rs_fill_spaces:
    ; Overwrites trailing garbage and pads short names to keep UI symmetric
    CMP CX, 14
    JAE rs_terminate
    MOV BYTE PTR [DI], ' '
    INC DI
    INC CX
    JMP rs_fill_spaces
    
rs_terminate:
    MOV BYTE PTR [DI], '$' ; Terminate the string at the 15th byte
    POP DI
    POP CX
    POP AX
    RET
ReadString ENDP

END MAIN
