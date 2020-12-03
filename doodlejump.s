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

platformLocations: .word 0:3       # array of size 3 to store the locations of the platforms
                                   # first is bottom then middle then top
                                   # initialized to top left square of display

doodlerLocation:       .word 0     # location of the bottom left square of the doodler
                      

                                    
doodlerFigureArray:    .word 0:7   # array of size 7 with the displacements for drawing the different parts of the doodler

.text

Main: 

# Initializes the doodlerFigureArray with the different displacements for the different parts of the doodler
# order is left to right then bottom to up 
la $t9, doodlerFigureArray    # $t9 stores the address of the first item in the array
addi $t3, $zero, 0             # $t3 stores the displacement for one part
sw $t3, 0($t9)                 # bottom left leg
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


# Initializes the platformLocations to be the left square on the desired row
# bottom platfom on bottom row of display
# platforms have 10 squares in between them
lw $t0, displayAddress            # $t0 stores the base address for display
la $t9, platformLocations         # $t9 stores the address in memory where the address of the bottom platform is stored
addi $t3, $t0, 3968               # the bottom platform is starts on the left square of the bottom row
sw $t3, 0($t9)                    # store location of bottom platform row
addi $t3, $t3, -1408              # go up 11 rows (-128 per row x 11 rows = -1408)    
sw $t3, 4($t9)                    # store location of middle platform row
addi $t3, $t3, -1408              # go up 11 rows (-128 per row x 11 rows = -1408)     
sw $t3, 8($t9)                    # store location of bottom platform row


StartDrawPlatforms:
# Drawing the 3 platforms at the start of game
jal StartDrawSky                     # first draw the sky
lw $t0, displayAddress               # $t0 stores the base address for display
la $s7, platformLocations            # $s7 stores the address of the array with platform locations - bottom first
addi $s6, $s7, 12                    # $s6 stores the address of the last location in the platformLocations array
StartDrawPlatformsLoop:
beq $s7, $s6, ExitStartDrawPlatforms # exit loop after drawing 3 platforms
lw $a2 0($s7)                        # parameter for GenerateRandomPlatformLocation -- displace the address stored at $s7
addi $a3, $s7, 0                     # parameter for GenerateRandomPlatformLocation -- store the new address at $s7
jal GenerateRandomPlatformLocation   # applies random horizontal displacement to address $a2 and stores it at $a3
lw $a3, 0($s7)                       # parameter for StartDrawOnePlatform- location we want to draw at
jal StartDrawOnePlatform             # start to draw one of the platforms
addi $s7, $s7, 4                     # move address to next word in array
j StartDrawPlatformsLoop             # jump back to beginning of loop
ExitStartDrawPlatforms:
jal StartDrawDoodler                 # now we go to draw the doodler
jal BounceUpFromBottom               # now the doodler bounces up



StartDrawOnePlatform:
addi $sp, $sp, -4                 # moving pointer
sw $ra, 0($sp)                    # pushing value of $ra into stack
# displays a flat platform is 8 units long starting at  the address stored at $a3
# PARAMETER: $a3 stores the location of the leftmost square of the platform 
addi $t9, $a3, 0                  # $t9 is the address of the current square being drawn on the platform 
                                  #  starts from the left and goes right
addi $t8, $t9, 32                 # $t8 is the address of the sky square to the right of the platform (which is 8 units long x 4= 32)
lw $t7, platformColour            # $t7 stores the colour of the platform
DrawOnePlatform: 
# displays a flat platform is 8 units long starting at $t9 and ending just before $t8
beq $t9, $t8, EndDrawOnePlatform  # branches if $t9 = $t8
sw $t7, 0($t9)                    # stores the platform colour into the corrisponding address
addi $t9, $t9, 4                  # t9 = $t9 + 4 - incrementing to next square of platform (right)
j DrawOnePlatform                 # jumps back to start of DisplayPlatform
EndDrawOnePlatform:
addi $t9, $t9, -32                # set $t9 back the leftmost square of current platform   --- TODO _________________ needed???________________
lw $ra, 0($sp)                    # popping value of $ra out of stack 
addi $sp, $sp, 4                  # move pointer
jr $ra                            # exit out of function

GenerateRandomPlatformLocation:
addi $sp, $sp, -4     # moving pointer
sw $ra, 0($sp)        # pushing value of $ra into stack
# generating a random number for the platform - stored in $t4
# representing horizontal  displacement from the left
# width of display is 32 but don't want platform to be cut off (platform is 8 squares wide)
# so the random number is between 0 and 23 (31-8)
# then applying the displacement to the address $a2 and storing it in memory at address $a3
# PARAMETER: $a2 stores the address to displace
# PARAMETER: $a3 stores the address in memory to store the displaced address
# note: uses $a0 and $a1
li $v0, 42            # random number generator with given range
li $a0, 0             # id of the random number generator
li $a1, 23            # maximum value of random number produced
syscall               # random number will be in $a0
# then mutliply the random number by 4 so it is word aligned
addi $t0, $zero, 4    # $t0 stores 4
mult $a0, $t0        # multiply random number by 4 and stores in  lo (hi not used since numbers are small)
mflo $t1              # store the random number from lo in $t1
add $t2, $a2, $t1     # add the random number to $a2 and store it in $t2
sw $t2, 0($a3)        # store the displaced address in the specified address in memory 
# jump out of function
lw $ra, 0($sp)        # popping value of $ra out of stack 
addi $sp, $sp, 4      # move pointer
jr $ra                # exit out of function


StartDrawSky:
addi $sp, $sp, -4                  # moving pointer
sw $ra, 0($sp)                     # pushing value of $ra into stack
# fills the entire display with skyColour
lw $t0, displayAddress             # $t0 stores the base address for display
addi $t9, $t0, 0                   # $t9 stores square being painted blue -- starts at top left corner
addi $t8, $t0, 4096                # $t8 stores the address after the last square that would be painted  (4092+4)
lw $t7, skyColour                  #$t7 stores the colour of the sky
DrawSkyLoop:
# fill the entire display with blue
beq $t9, $t8, EndDrawSky   # branches if the bottom right corner is passed
sw $t7 0($t9)                      # stores the sky colour in the square with address at $t9
addi $t9, $t9, 4                   # incrementing to next square
j DrawSkyLoop                          # jump back to start of DrawSky
EndDrawSky:
lw $ra, 0($sp)                     # popping value of $ra out of stack 
addi $sp, $sp, 4                   # move pointer
jr $ra                             # exit out of function

StartDrawDoodler:
addi $sp, $sp, -4              # moving pointer
sw $ra, 0($sp)                 # pushing value of $ra into stack
# stores start of doodler's location at beginning of game
# doodler starts in the middle of the bottom platform
la $t0, platformLocations      # address of where the bottom platform is stored
lw, $t9, 0($t0)                # t9 stores the address of bottom right corner of doodler
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


DropDown:
# makes doodler fall
# exits if doodler falls below platform
lw $t9, doodlerLocation  # $t9 stores the location of the doodler
lw $t0, displayAddress   # $t0 stores the address of the top left square of the display
addi $s1, $t0, 4092      # $s1 stores the bottom right square of the display
DropDownLoop:
bgt $t9, $s1, Exit       # exits program if doodler drops below the screen
jal Sleep                # sleeps 
jal EraseDoodler         # erase the previous position of doodler
lw $t4, 0xffff0000       # $t5 will be 1 if there is keyboard input
beq $t4, 1, KeyboardInput# keyboard input detected
jal CheckPlatform        # check if doodler hits the bottom platform - if it does, doodler bounces up 
addi $a1, $zero, 128     # parameter for MoveDoodler
jal MoveDoodler          # moves the doodler down by 1 square
lw $t9, doodlerLocation  # load updated doodler location
j DropDownLoop           # jump back to begining of loop

CheckPlatform:
addi $sp, $sp, -4                   # moving pointer
sw $ra, 0($sp)                      # pushing value of $ra into stack
# checks if there is platform below doodler to bounce up from
lw $t7, platformColour              # $t7 stores the colour of the platforms
lw $t9 doodlerLocation              # $t9 stores the address of the square to check for platform
addi $t9, $t9, 128                  # move down 1 row +128
lw $t8, 0($t9)                      # $t8 stores the colour of the square to check for platform
addi $t6, $t9, 12                   # $t6 stores the last square to check -- doodler is 3 squares wide x 4 = 12
CheckPlatformLoop:
beq $t9, $t6, EndCheckPlatform      # ends loop after reaching the last square to check
beq $t8, $t7, CheckWhichPlatform    # if the square is a platform (has platform colour), the the doodler bounces up
addi $t9, $t9, 4                    # move one square right (+4)
lw $t8, 0($t9)                      # $t8 stores the colour of the square to check for platfom
j CheckPlatformLoop                 # jump back to beginning of loop
EndCheckPlatform:
lw $ra, 0($sp)                      # popping value of $ra out of stack 
addi $sp, $sp, 4                    # move pointer
jr $ra                              # exit out of function


CheckWhichPlatform:
# checks if doodler bounced on the bottom or middle platform
# doodler should only be able to bounce from bottom two platforms
# we already know by this point the doodler has touched some platform
#TODO MAKE SURE THIS IS THE CASE --- as long as the platforms move at least as quickly as doodler _____________________________________________
# check using doodler location. 
# if it's the bottom platform, then it should be on the 2nd to last row of display offset from display address 3840-396\
# so could just check if doodler location is >= displayAddress + 38404
lw $t0, displayAddress   # $t0 stores the address of the top left square of the display
addi $t1, $t0, 3840      # $t1 stores the address of the left square on the 2nd to last row
lw $t9, doodlerLocation  # $t9 stores the location of the doodler 
bge $t9, $t1, IsBottom   # branches if the doodler location is within the bottom 2 rows
IsMiddle:
j BounceUpFromMiddle     # if the platform below the doodler is the middle platform
IsBottom:
j BounceUpFromBottom     # if the platform below the doodler is the bottom platform
  

BounceUpFromMiddle: 
# TODO: finish_________________________________________________________________________________________________________________________
# bounces up and moves platforms 
# doodler can move up 15 squares
# first move up 11 squares with platforms, then move remaining 4 with only doodler moving
jal FirstRedrawPlatform   # first 2 of the 11 need to be diff since generate new platform
addi $s1, $zero, 9        # platforms move up 11- 2 (from FirstDrawPlatform) = 9 squares
BounceUpFromMiddleLoop:
beq $zero, $s1, DropDown  # end loop after 9 iterations
jal  RedrawScreen         # redraw the platforms 1 square up
jal EraseDoodler          # erase the previous doodler
jal CheckKeyboardInput    # check for keyboard input for side movement
lw $a3, doodlerColour     # parameter for DrawDoodler
lw $a2, skyColour         # parameter for DrawDoodler
jal DrawDoodler           # redraw the doodler in row above
# AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
addi $s1, $s1, -1         # increment $t3
j BounceUpFromMiddleLoop  # jump back to begining of loop
#TODO update - change drop down to 2nd loop ------------------------------------------------------------------------------------------



FirstRedrawPlatform: 
addi $sp, $sp, -4                    # moving pointer
sw $ra, 0($sp)                       # pushing value of $ra into stack
# start here when moving the platforms up
la $t1, platformLocations            # $t1 stores the address for array that stores the platform Locations
lw $t2, 4($t1)                       # address of the middle platform
sw $t2, 0($t1)                       # set previous middle platform's address to be the new bottom platform
lw $t2, 8($t1)                       # address of the top platform 
sw $t2, 4($t1)                       # set previous top platform's address to middle 
                                     # note that previous top is still top
                                     # so  top platform i same as middle (so no extra platforms are drawn)
jal RedrawScreen                     # redraw screen with platforms moved up 
jal RedrawScreen                     # x2
# -----------------------------------------------------------------------------------------------------------------------------------

lw $t0, displayAddress               # $t0 stores the address of the top left corner of the display 
                                     # the top platform would be on the top row
la $t1, platformLocations 
addi $a2, $t0, 0                     # parameter for GenerateRandomPlatformLocation -- displace the top address
li $a3, 0                     
addi $a3, $t1, 8                     # parameter for GenerateRandomPlatformLocation -- store the new address 8($t1)
jal GenerateRandomPlatformLocation   # applies random horizontal displacement to address $a2 and stores it at $a3
la $t1, platformLocations            # $t1 stores the address for array that stores the platform Locations
lw $a3, 8($t1)                       # parameter for StartDrawOnePlatform- location we want to draw at-- top platform
jal StartDrawOnePlatform             # start to draw one of the platforms

# jump out of function
lw $ra, 0($sp)         # popping value of $ra out of stack 
addi $sp, $sp, 4       # move pointer
jr $ra                 # exit out of function


RedrawScreen:
addi $sp, $sp, -4     # moving pointer
sw $ra, 0($sp)        # pushing value of $ra into stack
# redraws the entire screem with platforms moved up 1 square
jal StartDrawSky      # draw sky first
# -----------------------------------------------------------------------------------...fix flashness perhaps undraw then redraw?
lw $a3, doodlerColour #  parameter for DrawDoodler
lw $a2, skyColour     #  parameter for DrawDoodler
jal DrawDoodler       #  redraw the doodler in row abov
jal MovePlatformsUp   # draw each of the platform moved up
# jump out of function
lw $ra, 0($sp)        # popping value of $ra out of stack 
addi $sp, $sp, 4      # move pointer
jr $ra                # exit out of function


MovePlatformsUp: 
addi $sp, $sp, -4             # moving pointer
sw $ra, 0($sp)                # pushing value of $ra into stack
# draws platfroms on the display moved up 1 square
addi $t3, $zero, 3
la $t1, platformLocations     # $t1 stores the address of the array that the address of the platform is
MovePlatformUpLoop:
beqz $t3, EndMovePlatformUp    # end loop after the 3 platforms have been drawn
lw $t2, 0($t1)                # $t2 stores the address of the left square of the platform
addi $t2, $t2, +128           # move addresss of the platfroms down 1 row (+128)
sw $t2, 0($t1)                # store the updated address of the platform
lw $a3, 0($t1)                # $a3 parameter for StartDrawOnePlatform -- location of the leftmost square of the platform
jal StartDrawOnePlatform      # draw the platform 
addi $t1, $t1, 4              # increment address in array for platformLocations
addi $t3, $t3, -1             # increment $t3
j MovePlatformUpLoop          # jump back to beginning of loop
EndMovePlatformUp:
lw $ra, 0($sp)                # popping value of $ra out of stack 
addi $sp, $sp, 4              # move pointer
jr $ra                        # exit out of function


BounceUpFromBottom:
# bounces up without moving platforms.
# doodler can move up 15 squares
addi $s1, $zero, 15       # doodler can move up 15 squares
BounceUpFromBottomLoop:
beq $zero, $s1, DropDown  # end loop once doodler moves up 15 squares
jal BounceUp              # doodler move up 1 square w side movement
addi $s1, $s1, -1         # increment $t3
j BounceUpFromBottomLoop  # jump back to begining of loop

BounceUp:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# allow doodler to move up 1 square with side movement too
jal Sleep                 # sleeps
jal EraseDoodler          # erase the previous position of doodler
jal CheckKeyboardInput    # check for keyboard input
addi $a1, $zero, -128     # parameter for MoveDoodler
jal MoveDoodler           # move doodler up 1 square (-128 in $a1)
# jump out of function
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

MoveDoodler:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# moves up doodler by offset specified in $a1
# PARAMETER: $a1 stores the offset to move the doodler by(relative to display)
lw $t9, doodlerLocation   # load the address of the bottom left square of the doodler
add $t9, $t9, $a1         # update the position of doodler by ofset specified by value in $a1
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
li $a0, 25        # sleep for 250 milliseconds
syscall
# jump out of function
lw $ra, 0($sp)    # poping value of $ra out of stack 
addi $sp, $sp, 4  # move pointer
jr $ra            # exit out of function


CheckKeyboardInput:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# checks for keyboard input
lw $t4, 0xffff0000        # $t5 will be 1 if there is keyboard input
beq $t4, 1, KeyboardInput # keyboard input detected
EndCheckKeyboardInput: 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function


KeyboardInput:
lw $t4, 0xffff0004       # the ASCII value of the key that was pressed
beq $t4, 0x6A, Pressedj  # j was pressed
beq $t4, 0x6B, Pressedk  # k was pressed
beq $t4, 0x73, Presseds  # s was pressed
j EndCheckKeyboardInput  # jump out of function if any other key pressed
Pressedj:   # move to left
lw $t9 doodlerLocation   # $t9 stores the location of the doodler
addi $t9, $t9, -4        # sub 4 (move left one square) to location
sw $t9, doodlerLocation  # store location back into doodlerLocation
j EndCheckKeyboardInput  # exit out of function
Pressedk:   # move to right
lw $t9 doodlerLocation   # $t9 stores the location of the doodler
addi $t9, $t9, 4         # add 4 (move right one square) to location
sw $t9, doodlerLocation  # store location back into doodlerLocation
j EndCheckKeyboardInput  # exit out of function
Presseds:   # exit 
j Exit                   # exit program



#travel down() -- 
#   if hit platform: bounce up ()
# else: keep going down until hit bottom of screen

# condition if doodler hits a platform on the way down and bouncesto move platforma up
# doodler could only reach bottom platform

# lives??? hearts

Exit:
li $v0, 10            # terminate the program gracefully
syscall
