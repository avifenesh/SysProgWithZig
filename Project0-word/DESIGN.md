# Part 1 Design - Count Words:

### This part of the program is kinda simple:

1. Get the file path from the user, through the command line arguments or through the standard input.
2. Open the file.
3. Allocate a buffer to read the file line by line.
4. Read the file line by line, clean special characters, and count the words.
5. Print the number of words in the file.

### The design of the program:

utils.zig will contain utility functions that will be used in the program:

-   Open files.
-   Allocate memory.
-   Read line from file.
-   Get a line and clean special characters.
-   Get a line and return the number of words.
-   Print into stdout.

count_words.zig will contain the main function that will call the utility functions:

-   main.zig will be used later for all the parts of the project, it will be responsible for parsing command line arguments and calling the main function of each part based on the arguments, then it will print the result.
-   count_words.zig will contain the main function that will call the utility functions and return the result to main.zig.
-   Tests will be written in the count_words_test.zig file to test the utility functions, and the main function using dummy files.
