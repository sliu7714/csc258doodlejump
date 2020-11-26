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
skyColour: .word 0xd6edee          # a blue colour for the sky
platformColour: .word 0x91c078     # a green colour for the platforms
doodlerColour: .word 0xc7bfec      # a purple colour for the doodler 

doodlerLocation: .word  # location of the top left square of the doodler
.text
lw $t0, displayAddress # $t0 stores the base address for display
#li $t1, 0xd6edee  # sky
#li $t2, 0x91c078 # $t2 stores the green colour code
#li $t3, 0xc7bfec # $t3 stores the purple olour code
#sw $t1, 0($t0) # paint the first (top-left) unit red.
#sw $t2, 4($t0) # paint the second unit on the first row green. Why $t0+4?
#sw $t3, 128($t0) # paint the first unit on the second row blue. Why +128?
#DisplayDoodler:
# doodler generated in the middle of the first platform
#sw $t3, 

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
# Drawing the 3 platforms
addi $t2, $t0, 3968    # $t6 stores the address of the rightmost square of the row that the platform will be on -- first starts with bottom right square     
addi $t3, $zero, 2     # $t5 stores the platform that is curently being drawn starts at 3 and goes down
j GenerateRandomPlatformLocation# first platform doesn't need to be incremented

MoveRow:
# moves up row up 10 squares
# there will be 10 units between platforms
blez $t3, Exit    # branch after the last platform is drawn
addi $t2, $t2, -1280   # going up 1 row is difference of -128 so 10 rows is 10(-128) = -1280
addi $t3, $t3, -1      # count the row # we are on


GenerateRandomPlatformLocation:
# generating a random number for the platform - stored in $t4
# representing horizontal placement
# width of display is 32 but don't want platform to be cut off (platform is 8 squares wide)
# so the random number is between 0 and 23 (31-8)
li $v0, 42            # random number generator with given range
li $a0, 0             # id of the random number generator
li $a1, 23            # maximum value of random number produced
syscall               # random number will be in $a0
# then mutliply the random number by 4 so it is word aligned
addi $t7, $zero, 4    # $t7 stores 4
mult $a0, $t7         # multiply random number by 4 and stores in  lo (hi not used since numbers are small)
mflo $t4              # store the random number in lo in $43

#TODO: move later
addi $t8, $zero, 2
beq $t3, $t8, StartDrawDoodler      #start drawing doodler before 1st platform now that we know the location of it


StartDrawOnePlatform:
# $t9 is the address of the current square being drawn on the platform -- starts from the left and goes right
add $t9, $t2, $t4      # first start at the row specified by $t2 offset by the random number in $t4
addi $t8, $t9, 32      # $t8 is the address of the sky square to the right of the platform (which is 8 units long x 4= 32)
lw $t7, platformColour # $t7 stores the colour of the platform
DrawOnePlatform: 
# displays a flat platform is 8 units long starting at $t9 and ending just before $t8
beq $t9, $t8, MoveRow  # branches if $t9 = $t8
sw $t7, 0($t9)         # stores the platform colour into the corrisponding address
addi $t9, $t9, 4       # t9 = $t9 + 4 - incrementing to next square of platform (right)
j DrawOnePlatform      # jumps back to start of DisplayPlatform



StartDrawDoodler:
# doodler starts in the middle of the bottom platform
			        # t9 stores the address of bottom right corner of doodler
add $t9, $t2, $t4              # right square of platform
addi $t9, $t9, -116            # move up 1 row -128, then move right +12(3 units)
addi $t8, $zero, 2             # $t8 stores the # of blocks being drawn (-1 since 0 is counted)
lw $t7, doodlerColour          # $t7 stores the colour of the doodler
DrawDoodler:
blez $t8, StartDrawOnePlatform # branches once all squares of doodler are drawn

#draw square first   TODO: change later
sw $t7, 0($t9)                 # stores the doodler colour to corrispoinding address
addi $t9, $t9, 4               # increment address by 1

addi $t8, $t8, -1              # remove 1 from total blocks still needed to be drawn
j DrawDoodler                  # go back to draw more squares


# condition if doodler hits a platform on the way down and bouncesto move platforma up
# doodler could only reach bottom platform


Exit:
li $v0, 10            # terminate the program gracefully
syscall