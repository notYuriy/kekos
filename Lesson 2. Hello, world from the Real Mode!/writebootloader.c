#include <stdio.h>
#include <stdlib.h>

// Bootloader install utility
// Copies bootloader in a way that preserves MBR
// Bootloader that are up to 32k size are supported
// Usage: ./writebootloader <path to MBR image> <path to bootloader binary>

int main(int argc, char **argv) {

    // Parsing command line arguments
    if (argc != 3) {
        perror("Usage: ./writebootloader <path to MBR image> <path to bootloader binary>\n");
        return EXIT_FAILURE;
    }
    const char *image_path = argv[1];
    const char *bootloader_path = argv[2];

    // Opening files 
    // imageFile is opened for writing (r+b), as we are modifying the image
    // bootloaderFile is opened for reading only, as we don't need
    // to modify it
    FILE* image_file = fopen(image_path, "r+b");
    FILE* bootloader_file = fopen(bootloader_path, "rb");
    if (image_file == NULL || bootloader_file == NULL) {
        perror("Can't open files\n");
        return EXIT_FAILURE;
    }

    /// Determine the size of the bootloader

    // Moving in the end of the file
    // SEEK_END means that position (second argument)
    // is relatve to the end of the file
    fseek(bootloader_file, 0, SEEK_END);

    // Getting the position in the file
    long bootloader_size = ftell(bootloader_file);
    if (bootloader_size < 0) {
        perror("Failed on ftell call: negative value was returned\n");
        return EXIT_FAILURE;
    }

    // Returning back to the start of the bootloader
    // SEEK_SET means that position (second argument)
    // is relatvie to the start of the file
    fseek(bootloader_file, 0, SEEK_SET);

    // Check that size is within bounds we support
    if (bootloader_size > 32768) {
        perror("Bootloader is too large\n");
        return EXIT_FAILURE;
    }

    // Creating buffer to store bootloader in memory
    char *bootloader_binary = malloc(bootloader_size);
    if (bootloader_binary == NULL) {
        perror("Failed to allocate memory to store bootloader binary\n");
        return EXIT_FAILURE;
    }

    // Reading from the bootloader file to the buffer
    if (fread(bootloader_binary, 1, bootloader_size, bootloader_file) != bootloader_size) {
        perror("Failed to read the file into memory");
        return EXIT_FAILURE;
    }

    // Writing the first 446 files to the image
    long first_part_size = bootloader_size < 446 ? bootloader_size : 446;
    if (fwrite(bootloader_binary, 1, first_part_size, image_file) != first_part_size) {
        perror("Error writing to file");
        return EXIT_FAILURE;
    }

    // Store everything else left from the bootloader
    if (bootloader_size < 512) {
        // This bootloader is small, it doesn't have second part (starting from 512 bytes)
        return EXIT_SUCCESS;
    }

    // Writing second part. Calculating second part size 
    // (everything that is not in the first sector)
    long second_part_size = bootloader_size - 512;

    // Moving the cursor in file image_file to 512 bytes
    fseek(image_file, 512, SEEK_SET);

    // Writing the second part to the image
    if (fwrite(bootloader_binary + 512, 1, second_part_size, image_file) != second_part_size) {
        perror("Error writing to file");
        return EXIT_FAILURE;
    }

    // We are done.
    return EXIT_SUCCESS;

}