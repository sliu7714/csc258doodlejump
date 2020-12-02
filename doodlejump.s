# Demo for painting
#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Siyuan (Kate) Liu, 1005734341
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.data
displayAddress: .word 0x10008000   # the address of the top left corner of the bitmap display
skyColour:      .word 0xd6edee     # a blue colour for the sky
platformColour: .word 0x91c078     # a green colour for the platforms
doodlerColour:  .word 0xc7bfec     # a purple colour for the doodler 

doodlerLocation:       .word 0     # location of the bottom left square of the doodler
topPlatformLocation:   .word 0     # location of the leftmost square of the top platform
midPlatformLocation:   .word 0     # location of the leftmost square of the middle platform
bottomPlatformLocation:.word 0     # location of the leftmost square of the bottom platform
                         
doodlerFigureArray:    .space 7    # array of size 7 with the displacements for drawing the different parts of the doodler


.text
lw $t0, displayAddress         # $t0 stores the base address for display

# Initializes the doodlerFigureArray with the different displacements for the different parts of the doodler
# order is left to right then bottom to up 
la $t9, doodlerFigureArray    # $t9 stores the address of the first item in the array
addi $t3, $zero, 0             # $t3 stores the displacement for one part
sw $t3, doodlerFigureArray                 # bottom left leg
addi $t3, $zero, 8 
sw $t3, 4($t9)                 # bottom right leg -- 2 right + 8
addi $t3, $zero, -124
sw $t3, 8($t9)                 # middle square -- 1 row up (-128) and 1 right (+4)
addi $t3, $zero, -256
sw $t3, 12($t9)                # right arm -- up 2 rows (-256)
addi $t3, $zero, -252
sw $t3, 16($t9)                # chest -- up 2 rows (-256), right 1 (+4)
addi $t3, $zero, -248
sw $t3, 20($t9)                # left arm -- up 2 rows (-256), right 2 (+8)
addi $t3, $zero, -380
sw $t3, 24($t9)                # head -- 3 rows up (-384), 1 right (+$)
#TODO: need to test thi

Main: 

StartDrawSky:
addi $t9, $t0, 0    # $t9 stores square being painted blue -- starts at top left corner
addi $t8, $t0, 4096 # $t8 stores the address after the last square that would be painted  (4092+4)
lw $t7, skyColour   #$t7 stores the colour of the sky
DrawSky:
# fill the entire display with blue
beq $t9, $t8, StartDrawPlatforms   # branches if the bottom right corner is passed
sw $t7 0($t9)                      # stores the sky colour in the square with address at $t9
addi $t9, $t9, 4                   # incrementing to next square
j DrawSky                          # jump back to start of DrawSky



#TODO change 3968 to var later to know rel address of row of bottom platform
StartDrawPlatforms:
# Drawing the 3 platformss
addi $t2, $t0, 3968               # $t2 stores the address of the rightmost square of the row that the platform will be on -- first starts with bottom right square   
jal GenerateRandomPlatformLocation# this stores a random horizontal offset for address of platform in $t4
jal StartDrawOnePlatform          # start to draw BOTTOM platform
                                  # t9 now stores the address of the bottom platform
sw $t9, bottomPlatformLocation    # store location of bottom platform

addi $t2, $t2, -1280              # moves row of platform up 10 squares
                                  # going up 1 row is difference of -128 so 10 rows is 10(-128) = -1280           
jal GenerateRandomPlatformLocation# this stores a random horizontal offset for address of platform in $t4             
jal StartDrawOnePlatform          # start to draw the MIDDLE platform
sw $t9, midPlatformLocation       # store the location of middle platform

addi $t2, $t2, -1280              # moves row of platform up 10 squares
jal GenerateRandomPlatformLocation# this stores a random horizontal offset for address of platform in $t4
jal StartDrawOnePlatform          # start to draw TOP platform
sw $t9 topPlatformLocation        # store location of top platform

jal StartDrawDoodler              #  now we go to draw the doodler
jal BounceUpFromBottom  #TODO change!!!

#MoveRow:
# moves up address in $t2 up 10 squares(rows)
# there will be 10 units between platforms
#addi $t2, $t2, -1280   # going up 1 row is difference of -128 so 10 rows is 10(-128) = -1280
#jr $ra                 # jump back out of function


StartDrawOnePlatform:
addi $sp, $sp, -4 # moving pointer
sw $ra, 0($sp)    # pushing value of $ra into stack
# $t9 is the address of the current square being drawn on the platform -- starts from the left and goes right
add $t9, $t2, $t4                 # first start at the row specified by $t2 offset by the random number in $t4
addi $t8, $t9, 32                 # $t8 is the address of the sky square to the right of the platform (which is 8 units long x 4= 32)
lw $t7, platformColour            # $t7 stores the colour of the platform
DrawOnePlatform: 
# displays a flat platform is 8 units long starting at $t9 and ending just before $t8
beq $t9, $t8, EndDrawOnePlatform  # branches if $t9 = $t8
sw $t7, 0($t9)                    # stores the platform colour into the corrisponding address
addi $t9, $t9, 4                  # t9 = $t9 + 4 - incrementing to next square of platform (right)
j DrawOnePlatform                 # jumps back to start of DisplayPlatform
EndDrawOnePlatform:
addi $t9, $t9, -32                # set $t9 back the leftmost square of current platform
lw $ra, 0($sp)    # popping value of $ra out of stack 
addi $sp, $sp, 4  # move pointer
jr $ra            # exit out of function

GenerateRandomPlatformLocation:
addi $sp, $sp, -4 # moving pointer
sw $ra, 0($sp)    # pushing value of $ra into stack
# generating a random number for the platform - stored in $t4
# representing horizontal  displacement from the left
# width of display is 32 but don't want platform to be cut off (platform is 8 squares wide)
# so the random number is between 0 and 23 (31-8)
li $v0, 42            # random number generator with given range
li $a0, 0             # id of the random number generator
li $a1, 23            # maximum value of random number produced
syscall               # random number will be in $a0
# then mutliply the random number by 4 so it is word aligned
addi $t7, $zero, 4    # $t7 stores 4
mult $a0, $t7         # multiply random number by 4 and stores in  lo (hi not used since numbers are small)
mflo $t4              # store the random number from lo in $4
# jump out of function
lw $ra, 0($sp)    # popping value of $ra out of stack 
addi $sp, $sp, 4  # move pointer
jr $ra            # exit out of function



StartDrawDoodler:
addi $sp, $sp, -4              # moving pointer
sw $ra, 0($sp)                 # pushing value of $ra into stack
# stores start of doodler's location at beginning of game
# doodler starts in the middle of the bottom platform
lw, $t9, bottomPlatformLocation# t9 stores the address of bottom right corner of doodler
addi $t9, $t9, -116            # move up 1 row -128, then move right +12(3 units)
sw $t9, doodlerLocation        # store the location of doodler in memory
lw $a3, doodlerColour          # parameter for DrawDoodler
lw $a2, skyColour              # parameter for DrawDoodler
jal DrawDoodler
# jump out of function
lw $ra, 0($sp)                 # popping value of $ra out of stack 
addi $sp, $sp, 4               # move pointer
jr $ra                         # exit out of function


DrawDoodler:
addi $sp, $sp, -4              # moving pointer
sw $ra, 0($sp)                 # pushing value of $ra into stack
# draws doodler(or over) at doodlerLocation with colour in $a3
# only draws over squares of colour $a2
# PARAMETER: $a2 stores the colour that we want to colour 
# PARAMETER: $a3 stores the colour we want to draw with
# draw the doodler one square at a time
la $t6, doodlerFigureArray     # the address of the offset from doodlerLocation of the current block being drawn
addi $t5, $t6, 28              # the address after the last square of the doodler -- 7 blocks x 4 = 28
DrawDoodlerLoop:             
beq $t6, $t5, EndDrawDoodler   # ends loop after reaching last block
lw $t4, ($t6)                  # $t4 stores the offset value  amount from dooderFigureArray
lw $a0, doodlerLocation        # $a0 stores the location of the square to colour- paramter for CheckSquareSky
add $a0, $a0, $t4              # apply offset in $t4 to $a0
jal CheckSquareSky             # colour square
addi $t6, $t6, 4               # incremennt $t6 no next address in doodlerFigureArray
j DrawDoodlerLoop              # go back to begining of loop
EndDrawDoodler:
# jump out of function
lw $ra, 0($sp)                 # popping value of $ra out of stack 
addi $sp, $sp, 4               # move pointer
jr $ra                         # exit out of function

CheckSquareSky:
addi $sp, $sp, -4                # moving pointer
sw $ra, 0($sp)                   # pushing value of $ra into stack
# we only want to colour with  $a3 over the block at address $a0 if it was the colour of $a3 
# PARAMETER: a0 stores the address of the square we want to check
# PARAMETER: a2 stores the colour that we want to colour over- sky or doodler
# PARAMETER: a3 stores the colour we want to colour the square
lw $t9, 0($a0)                   # colour at address $a0
bne $t9, $a2, ExitCheckSquareSky # if the square is not the colour in $a2, don't overwrite it, just go back
sw $a3, 0($a0)                   # colour the square the colour specified 
ExitCheckSquareSky:              # jump out of function
lw $ra, 0($sp)                   # poping value of $ra out of stack 
addi $sp, $sp, 4                 # move pointer
jr $ra                           # exit out of function


BounceUpFromMiddle: 
# bounces up and moves platforms 

BounceUpFromBottom:
# bounces up without moving platforms.
# doodler can move up 15 squares
addi $t3, $zero, 15       # doodler can move up 15 squares
BounceUpFromBottomLoop: 
beq $zero, $t3, DropDown  # end loop once doodler moves up 15 squares
jal Sleep                 # sleeps 
jal EraseDoodler          # erase the previous position of doodler

 # Todo: add options to moveleft and right ____________________________________________________________________________________
lw $t4, 0xffff0000       # $t5 will be 1 if there is keyboard input
beq $t4, 1, KeyboardInput # keyboard input detected

jal MoveUpOne             # move doodler up 1 square
addi $t3, $t3, -1         # increment $t3
j BounceUpFromBottomLoop  # jump back to begining of loop


DropDown:
# makes doodler fall
# exits if doodler falls below platform
   # TODO: check for platform mid, bottom, 
lw $t9, doodlerLocation
addi $t3, $t9, 4092      # the bottom right square of the display
DropDownLoop:
bgt $t9, $t3, Exit       # exits program if doodler drops below the screen
jal Sleep                # sleeps 
jal EraseDoodler         # erase the previous position of doodler

lw $t4, 0xffff0000       # $t5 will be 1 if there is keyboard input
beq $t4, 1, KeyboardInput # keyboard input detected

jal MoveDownOne          # moves the doodler down by 1 square
lw $t9, doodlerLocation  # load updated doodler location
j DropDownLoop           # jump back to begining of loop



MoveUpOne:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# moves up doodler by 1 square/row
lw $t9, doodlerLocation   # load the address of the bottom left square of the doodler
addi $t9, $t9, -128       # update the position of doodler up 1 row (-128)
sw $t9, doodlerLocation   # store updated location of doodler
lw $a3, doodlerColour     # parameter for DrawDoodler
lw $a2, skyColour         # parameter for DrawDoodler
jal DrawDoodler           # redraw the doodler in row above
# jump out of function
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function


MoveDownOne:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# moves down doodler by 1 square/row
lw $t9, doodlerLocation   # load the address of the bottom left square of the doodler
addi $t9, $t9, 128        # update the position of doodler down 1 row (+128)
sw $t9, doodlerLocation   # store updated location of doodler
lw $a3, doodlerColour     # parameter for DrawDoodler
lw $a2, skyColour         # parameter for DrawDoodler
jal DrawDoodler           # redraw the doodler in row above
# jump out of function
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

EraseDoodler:
addi $sp, $sp, -4     # moving pointer
sw $ra, 0($sp)        # pushing value of $ra into stack
# set the doodler squares back to skyColour 
# don't change colour if it's any colour that is not doodlerColour
lw $a3, skyColour     # parameter for DrawDoodler
lw $a2, doodlerColour # parameter for DrawDoodler
jal DrawDoodler
# jump out of function
lw $ra, 0($sp)        # popping value of $ra out of stack 
addi $sp, $sp, 4      # move pointer
jr $ra                # exit out of function


Sleep:
addi $sp, $sp, -4 # moving pointer
sw $ra, 0($sp)    # pushing value of $ra into stack
# sleeps for 1/2 sec
li $v0, 32        # command for sleep
li $a0, 250        # sleep for 250 milliseconds
syscall
# jump out of function
lw $ra, 0($sp)    # poping value of $ra out of stack 
addi $sp, $sp, 4  # move pointer
jr $ra            # exit out of function


KeyboardInput:
addi $sp, $sp, -4        # moving pointer
sw $ra, 0($sp)           # pushing value of $ra into stack
lw $t4, 0xffff0004       # the ASCII value of the key that was pressed
beq $t4, 0x6A, Pressedj  # j was pressed
beq $t4, 0x6B, Pressedk  # k was pressed
beq $t4, 0x73, Presseds  # s was pressed
j EndKeyboardInput       # jump out of function if any other key pressed
Pressedj:   # move to left
lw $t9 doodlerLocation   # $t9 stores the location of the doodler
addi $t9, $t9, 4         # add 4 (move right one square) to location
sw $t9, doodlerLocation  # store location back into doodlerLocation
j EndKeyboardInput       # exit out of function
Pressedk:   # move to right
lw $t9 doodlerLocation   # $t9 stores the location of the doodler
addi $t9, $t9, -4        # sub 4 (move left one square) to location
sw $t9, doodlerLocation  # store location back into doodlerLocation
j EndKeyboardInput       # exit out of function
Presseds:   # exit 
j Exit                   # exit program
EndKeyboardInput:
lw $ra, 0($sp)           # popping value of $ra out of stack 
addi $sp, $sp, 4         # move pointer
jr $ra                   # exit out of function

# keep in mind side movement later

# move side 
# move left
# move right

#travel down() -- 
#   if hit platform: bounce up ()
# else: keep going down until hit bottom of screen

# condition if doodler hits a platform on the way down and bouncesto move platforma up
# doodler could only reach bottom platform

Exit:
li $v0, 10            # terminate the program gracefully
syscall
