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
# - Milestone 3
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:\
# - After the losing the game press r to restart and s to exit the game, if nothing is pressed after 1 minute , the game ends
#
#####################################################################

# notes: deletelater
# - for some reason if mars is open for a long time the redrawing is pretty slow but restarting mars seems to fix it 
# - be careful address vs values at addresses
# - careful to not overrride things that are inportaint

.data
displayAddress: .word 0x10008000   # the address of the top left corner of the bitmap display
skyColour:      .word 0xd6edee     # a blue colour for the sky
platformColour: .word 0x91c078     # a green colour for the platforms
doodlerColour:  .word 0xc7bfec     # a purple colour for the doodler 
greyColour:     .word 0xa3a3a3     # a grey colour
yellowColour:   .word 0xefc050     # a yellow colour

score:          .word 0            # the score of the player

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



StartGame: 
sw $zero, score    # set score to 0 

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
#addi $t9, $t9, -32                 # set $t9 back the leftmost square of current platform   --- TODO _________________ needed???________________
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
mult $a0, $t0         # multiply random number by 4 and stores in  lo (hi not used since numbers are small)
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
j DrawSkyLoop                      # jump back to start of DrawSky
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
lw $t9, doodlerLocation       # $t9 stores the location of the doodler
lw $t0, displayAddress        # $t0 stores the address of the top left square of the display
addi $s1, $t0, 4092           # $s1 stores the bottom right square of the display
DropDownLoop:
bgt $t9, $s1, Restart         # stops game if doodler drops below the screen
jal Sleep                     # sleeps 
jal EraseDoodler              # erase the previous position of doodler
lw $t4, 0xffff0000            # $t5 will be 1 if there is keyboard input
beq $t4, 1, CheckKeyboardInput# keyboard input detected
jal CheckPlatform             # check if doodler hits the bottom platform - if it does, doodler bounces up 
addi $a1, $zero, 128          # parameter for MoveDoodler
jal MoveDoodler               # moves the doodler down by 1 square
lw $t9, doodlerLocation       # load updated doodler location
j DropDownLoop                # jump back to begining of loop

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
# bounces up and moves platforms 
# doodler can move up 15 squares
# first move up 11 squares with platforms, then move remaining 4 with only doodler moving
jal FirstRedrawPlatform   # first 2 of the 11 need to be diff since generate new platform
addi $s1, $zero, 9        # platforms move up 11- 2 (from FirstDrawPlatform) = 9 squares
BounceUpFromMiddleLoop:
beq $zero, $s1, DropDown  # end loop after 9 iterations
jal Sleep                 # sleep
jal RedrawScreen          # redraw the platforms 1 square up
jal EraseDoodler          # erase the previous doodler
jal CheckKeyboardInput    # check for keyboard input for side movement
lw $a3, doodlerColour     # parameter for DrawDoodler
lw $a2, skyColour         # parameter for DrawDoodler
jal DrawDoodler           # redraw the doodler in row above
addi $s1, $s1, -1         # increment $t3
j BounceUpFromMiddleLoop  # jump back to begining of loop


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
lw $t0, displayAddress               # $t0 stores the address of the top left corner of the display 
                                     # the top platform would be on the top row
la $t1, platformLocations            # $t1 stores the address for array that stores the platform Locations
addi $a2, $t0, 0                     # parameter for GenerateRandomPlatformLocation -- displace the top address
li $a3, 0                            # start with 0
addi $a3, $t1, 8                     # parameter for GenerateRandomPlatformLocation -- store the new address 8($t1)
jal GenerateRandomPlatformLocation   # applies random horizontal displacement to address $a2 and stores it at $a3
la $t1, platformLocations            # $t1 stores the address for array that stores the platform Locations
lw $a3, 8($t1)                       # parameter for StartDrawOnePlatform- location we want to draw at-- top platform
jal StartDrawOnePlatform             # start to draw one of the platforms
# jump out of function
lw $ra, 0($sp)                       # popping value of $ra out of stack 
addi $sp, $sp, 4                     # move pointer
jr $ra                               # exit out of function


RedrawScreen:
addi $sp, $sp, -4     # moving pointer
sw $ra, 0($sp)        # pushing value of $ra into stack
# redraws the entire screem with platforms moved up 1 square
# if drawing really slow usually restarting Mars will fix it 
jal StartDrawSky      # draw sky first
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
beqz $t3, EndMovePlatformUp   # end loop after the 3 platforms have been drawn
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
# sleep
li $v0, 32        # command for sleep
li $a0, 35        # sleep for specified millisecconds
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



Restart:
#TODO:---display game over msg___________________________________________________________________________________________________
#______________________________game over message__________________________________________________________________________________
lw $t7, greyColour     # the colour of the game over message
lw $t0, displayAddress # the address of the top left of the display
# skull one row at a time 
sw $t7, 432($t0)
sw $t7, 436($t0)
sw $t7, 440($t0)
sw $t7, 444($t0)
sw $t7, 448($t0)

sw $t7, 556($t0)
sw $t7, 560($t0)
sw $t7, 564($t0)
sw $t7, 568($t0)
sw $t7, 572($t0)
sw $t7, 576($t0)
sw $t7, 580($t0)

sw $t7, 680($t0)
sw $t7, 684($t0)
sw $t7, 688($t0)
sw $t7, 692($t0)
sw $t7, 696($t0)
sw $t7, 700($t0)
sw $t7, 704($t0)
sw $t7, 708($t0)
sw $t7, 712($t0)

sw $t7, 808($t0)
sw $t7, 812($t0)
sw $t7, 816($t0)
sw $t7, 820($t0)
sw $t7, 824($t0)
sw $t7, 828($t0)
sw $t7, 832($t0)
sw $t7, 836($t0)
sw $t7, 840($t0)

sw $t7, 936($t0)
sw $t7, 948($t0)
sw $t7, 952($t0)
sw $t7, 956($t0)
sw $t7, 968($t0)

sw $t7, 1064($t0)
sw $t7, 1076($t0)
sw $t7, 1080($t0)
sw $t7, 1084($t0)
sw $t7, 1096($t0)

sw $t7, 1192($t0)
sw $t7, 1196($t0)
sw $t7, 1200($t0)
sw $t7, 1204($t0)
sw $t7, 1212($t0)
sw $t7, 1216($t0)
sw $t7, 1220($t0)
sw $t7, 1224($t0)

sw $t7, 1324($t0)
sw $t7, 1328($t0)
sw $t7, 1332($t0)
sw $t7, 1336($t0)
sw $t7, 1340($t0)
sw $t7, 1344($t0)
sw $t7, 1348($t0)

sw $t7, 1456($t0)
sw $t7, 1460($t0)
sw $t7, 1464($t0)
sw $t7, 1468($t0)
sw $t7, 1472($t0)

sw $t7, 1584($t0)
sw $t7, 1592($t0)
sw $t7, 1600($t0)

# now draw letters, for all the letter cals $a2 is colour
add $a2, $zero, $t7

# P 
addi $a3, $t0, 1804 # parameter for drawing letter - location of top left square
jal DrawP
#R
addi $a3, $t0, 1820 # parameter for drawing letter - location of top left square
jal DrawR
#E
addi $a3, $t0, 1836 # parameter for drawing letter - location of top left square
jal DrawE
#S
addi $a3, $t0, 1848 # parameter for drawing letter - location of top left square
jal DrawS
#S
addi $a3, $t0, 1864 # parameter for drawing letter - location of top left square
jal DrawS

#R
addi $a3, $t0, 1888 # parameter for drawing letter - location of top left square
jal DrawR

#T
addi $a3, $t0, 2564 # parameter for drawing letter - location of top left square
jal DrawT
#O
addi $a3, $t0, 2580 # parameter for drawing letter - location of top left square
jal DrawO

#R
addi $a3, $t0, 2600 # parameter for drawing letter - location of top left square
jal DrawR
#E
addi $a3, $t0, 2616 # parameter for drawing letter - location of top left square
jal DrawE
# P 
addi $a3, $t0, 2628 # parameter for drawing letter - location of top left square
jal DrawP
# L
addi $a3, $t0, 2644 # parameter for drawing letter - location of top left square
jal DrawL
# A
addi $a3, $t0, 2656 # parameter for drawing letter - location of top left square
jal DrawA
# Y
addi $a3, $t0, 2672 # parameter for drawing letter - location of top left square
jal DrawY

#E
addi $a3, $t0, 3340 # parameter for drawing letter - location of top left square
jal DrawE

#T
addi $a3, $t0, 3364 # parameter for drawing letter - location of top left square
jal DrawT
#O
addi $a3, $t0, 3380 # parameter for drawing letter - location of top left square
jal DrawO

#E
addi $a3, $t0, 3400 # parameter for drawing letter - location of top left square
jal DrawE
#X
addi $a3, $t0, 3412 # parameter for drawing letter - location of top left square
jal DrawX
#I
addi $a3, $t0, 3428 # parameter for drawing letter - location of top left square
jal DrawI
#T
addi $a3, $t0, 3436 # parameter for drawing letter - location of top left square
jal DrawT

#_____________________________end game over message_______________________________________________________________________________

li $t5 60
CheckRestartLoop:         # loop that waits for user input to exit or restart
beq $t5, $zero, Exit      # if nothing was pressed after a minute, game ends.
# checks for keyboard input
lw $t4, 0xffff0000        # $t5 will be 1 if there is keyboard input
beq $t4, 1, CheckReplay   # keyboard input detected
# sleeps for 1 sec
li $v0, 32                # command for sleep
li $a0, 1000              # sleep for specified millisecconds
syscall
addi $t5, $t5, -1         # increment $t5
j CheckRestartLoop
# input was detected
CheckReplay:  
beq $t4, 0x65, Pressede  # e was pressed
beq $t4, 0x72, Pressedr  # r was pressed
Pressedr:  # replay
j StartGame              # start game again
Pressede:  # exit
j Exit              # start game again


# FUNCTIONS FOR DRAWING LETTERS AND NUMBERS________________________________________________________________________________________

# NUMBERS______________________________________________________________________________
Draw0:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw1:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)

sw $a2, 384($a3)

sw $a2, 512($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw2:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw3:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw4:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 392($a3)

sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw5:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw6:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw7:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 136($a3)

sw $a2, 264($a3)

sw $a2, 392($a3)

sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw8:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Draw9:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 392($a3)

sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

# LETTERS ____________________________________________________________________________
DrawP:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter P with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 512($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawR:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter R with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 388($a3)

sw $a2, 512($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawE:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter E with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)

sw $a2, 384($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawS:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter S with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function


DrawT:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter T with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 132($a3)

sw $a2, 260($a3)

sw $a2, 388($a3)

sw $a2, 516($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawO:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter  with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawL:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter  with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)

sw $a2, 384($a3)

sw $a2, 512($a3)
sw $a2, 516($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawA:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter  with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 4($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 384($a3)
sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawY:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter  with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 256($a3)
sw $a2, 260($a3)
sw $a2, 264($a3)

sw $a2, 388($a3)

sw $a2, 516($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawX:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter  with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)
sw $a2, 8($a3)

sw $a2, 128($a3)
sw $a2, 136($a3)

sw $a2, 260($a3)

sw $a2, 384($a3)
sw $a2, 392($a3)

sw $a2, 512($a3)
sw $a2, 520($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

DrawI:
addi $sp, $sp, -4         # moving pointer
sw $ra, 0($sp)            # pushing value of $ra into stack
# draws the letter  with the top left corner at $a3
# PARAMETER: $a3 is the address in the display where the top left of the letter will sit
# PARAMETER: $a2 is the colour of the letter to display
sw $a2, 0($a3)

sw $a2, 128($a3)

sw $a2, 256($a3)

sw $a2, 384($a3)

sw $a2, 512($a3)
# jumping out of function 
lw $ra, 0($sp)            # popping value of $ra out of stack 
addi $sp, $sp, 4          # move pointer
jr $ra                    # exit out of function

Exit:
li $v0, 10   # terminate the program gracefully
syscall

