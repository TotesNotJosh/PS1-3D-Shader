# ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
# Author: TotesNotJosh
# Date: 1/3/2025
# Version: 1.0.1
# Description: A program that converts images to the PSX format. 256 x 256, 32 colours, and dithered black based transparency.
# Update: Updated transparency dither to work with PSX dither matrix format.
# ¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬
from PIL import Image
import os
import pickle

FOLDER_FILENAME = 'folder_filepath.pkl'
FINAL_HEIGHT = 256
PIXEL_SCALE = 1
DITHER_MATRIX = [[-4, 0, -3, 1],
                 [2, -2, 3, -1],
                 [-3, 1, -4, 0],
                 [3, -1, 2, -2]]

def reduce_images(input_folder, output_folder, file_extension):
    counter = 0
    print('Reducing images.')
    for file in os.listdir(input_folder):
            reduce_image(file, input_folder, output_folder, file_extension)
            counter += 1

def adjust_black_points(input_folder, output_folder, file_extension):
    counter = 0
    print('Adjusting blackpoint.')
    for file in os.listdir(input_folder):
            adjust_black_point(file, input_folder, output_folder, file_extension)
            counter += 1

def quantize_images(input_folder, output_folder, file_extension):
    counter = 0
    print('Adjusting colour depth.')
    for file in os.listdir(input_folder):
            quantize_image(file, input_folder, output_folder, file_extension)
            counter += 1

def do_all(input_folder, output_folder, file_extension):
    counter = 0
    print('PlayStation styling images.')
    for file in os.listdir(input_folder):
            the_works(file, input_folder, output_folder, file_extension)
            counter += 1

def exit():
    return

OPTIONS = {
    '1': reduce_images,
    '2': adjust_black_points,
    '3': quantize_images,
    '4': do_all,
    '5': exit}

def main():
    introduce_program()
    parent_folder = load_folder()
    input_folder = os.path.join(parent_folder, 'Unprocessed')
    output_folder = os.path.join(parent_folder, 'Processed')
    while True:
        display_menu()
        user_input = input('Enter Something. ')
        action = validate_input(user_input).lower()
        print(OPTIONS[action].__name__.title().replace("_", " "))
        if OPTIONS[action].__name__.title() == 'Exit':
            print('Now exiting the program.')
            break
        elif action in OPTIONS:
            file_extension = input('What file format would you like to save the image as? PNG or JPG? ')
            OPTIONS[action](input_folder, output_folder, file_extension)
        else:
            print('Something went wrong. Trying again.')

def introduce_program():
    print('Welcome to the PSX Image Converter.\n')
    print('This will allow you to convert images to the PSX format.')
    print('There are a few effects mainly for processing images so that the PSX GPU could handle images properly.')

def save_folder(folder):
    with open(FOLDER_FILENAME, 'wb') as file:
        pickle.dump(folder, file)

def load_folder():
    try:
        with open(FOLDER_FILENAME, 'rb') as file:
            return pickle.load(file)
    except:
        print("It looks like you don't have a parent folder set. Let's set that up.")
        print('This will create a folder called PSX Images in the parent folder, and two sub folders called Unprocessed and Processed.')
        print('It also saves the location to a pkl file so you can easily access it later.')
        folder = create_folder()
        save_folder(folder)
        print('Folders created.')
        print('Place any images you want to process in the Unprocessed folder and make sure they end with HD.')
        return folder

def create_folder():
    filepath = input('What is the folder path? ')
    while not os.path.exists(filepath):
        filepath = input('That folder does not exist. Please try again. ')
    filepath = os.path.join(filepath, r'PSX Images')
    new_folder = os.path.join(filepath, r'Unprocessed')
    if not os.path.exists(new_folder):
        os.makedirs(new_folder)
    new_folder = os.path.join(filepath, r'Processed')
    if not os.path.exists(new_folder):
        os.makedirs(new_folder)
    return filepath

def display_menu():
    print('What would you like to do?')
    for option, option_text in OPTIONS.items():#iterates through each option in the class's options dictionary and displays them as a menu
        print(f'{option}. {option_text.__name__.title().replace("_", " ")}')

def validate_input(user_input):
    while user_input not in OPTIONS and user_input.lower() not in OPTIONS.values(): #using title to try to match all ways to write the options
        user_input = input(f'Sorry {user_input} is invalid. Please Try again. ')
    if user_input.lower().replace(" ", "_") in OPTIONS.values():
        for key, value in OPTIONS.items():
            if value == user_input.lower().replace(" ", "_"):
                return key
    else:
        return user_input.strip()

def reduce_image(file, input_folder, output_folder, file_extension):
    if file.endswith("HD.jpg"):
        input = os.path.join(input_folder, file)
        image = Image.open(input).convert("RGB")
        output_file = file.replace("HD", "SD")
        output = os.path.join(output_folder, output_file)
        image = reduce_or_quantize(image)
        save_image(image, output, file_extension)

def adjust_black_point(file, input_folder, output_folder, file_extension):
    if file.endswith("HD.jpg"):
        input = os.path.join(input_folder, file)
        image = Image.open(input).convert("RGB")
        output_file = file.replace("HD", "SD")
        output = os.path.join(output_folder, output_file)
        image = black(image)
        save_image(image, output, file_extension)
    if file.endswith("HD.png"):
        input = os.path.join(input_folder, file)
        image = Image.open(input).convert("RGBA")
        output_file = file.replace("HD", "SD")
        output = os.path.join(output_folder, output_file)
        image = black(image)
        image = dither_transparency(image)
        save_image(image, output, file_extension)

def quantize_image(file, input_folder, output_folder, file_extension):
    if file.endswith("HD.jpg"):
        input = os.path.join(input_folder, file)
        image = Image.open(input).convert("RGB")
        output_file = file.replace("HD", "SD")
        output = os.path.join(output_folder, output_file)
        image = reduce_or_quantize(image, final_height = image.height, second_pass = True, total_colours = 32)
        save_image(image, output, file_extension)

def the_works(file, input_folder, output_folder, file_extension):
    input = os.path.join(input_folder, file)
    image = Image.open(input).convert("RGBA")
    if file.endswith("HD.jpg"):
        output_file = file.replace("HD", "SD")
        output = os.path.join(output_folder, output_file)
        image = reduce_or_quantize(image)
        image = reduce_or_quantize(image, final_height = image.height, second_pass = True, total_colours = 32)
        image = black(image)
    if file.endswith("HD.png"):
        output_file = file.replace("HD", "SD")
        output = os.path.join(output_folder, output_file)
        image = reduce_or_quantize(image)
        image = reduce_or_quantize(image, final_height = image.height, second_pass = True, total_colours = 32)
        image = black(image)
        image = dither_transparency(image)
    image = image.convert("RGB")
    save_image(image, output, file_extension)

def black(image):
    image = image.convert("RGBA")
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if r == 0 and g == 0 and b == 0: #True black was used for transparency so they added a hint of colour to make it visible usually red and/or blue
                r = 0
                g = 0
                b = 8 #8 because of the 32 colour palette
                a = a
            image.putpixel((x, y), (r, g, b, a))
    return image

def reduce_or_quantize(image, final_height = FINAL_HEIGHT, second_pass = False, total_colours = 256):
    width, height = image.size
    aspect_ratio = width / height
    new_height = final_height
    new_width = int(aspect_ratio * new_height)
    if new_width > FINAL_HEIGHT:
        new_width = FINAL_HEIGHT
        new_height = int(new_width / aspect_ratio)
    if height > final_height // PIXEL_SCALE:
        image = image.resize((new_width // PIXEL_SCALE, new_height // PIXEL_SCALE), Image.NEAREST)
    image = image.resize((new_width, new_height), Image.NEAREST)
    if second_pass == True:
        image = image.quantize(colors = total_colours, dither=None)
    return image

def dither_colours(image): #Shader dithers so this isn't fully needed but could be set up to pre-dither the image
    for y in range(image.height):
        for x in range(image.width):
            dither_matrix_y = DITHER_MATRIX[y % 4]
            dither_effect = dither_matrix_y[x % 4]
            r, g, b = image.getpixel((x, y))
            r = min(r + dither_effect, 255)
            g = min(g + dither_effect, 255)
            b = min(b + dither_effect, 255)
            image = image.putpixel((x, y), (r, g, b))
    return image

def dither_transparency(image):
    dither_transparency_matrix = [
        [4, 120, 30, 150],
        [180, 60, 210, 90],
        [30, 150, 4, 120],
        [210, 90, 180, 60]]
    width, height = image.size
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            threshold = dither_transparency_matrix[y % 4][x % 4]
            if a >= max(min(threshold, 255), 0):
                pixels[x, y] = (r, g, b, 255)
            else:
                pixels[x, y] = (0, 0, 0, 255)
    return image

def save_image(image, output, file_extension = 'png'):
    if file_extension.lower() == 'png':
        if output.endswith('.jpg'):
            output = output.replace('.jpg', '.png')        
        image.save(output, "PNG")
    elif file_extension.lower() == 'jpg':
        if output.endswith('.png'):
            output = output.replace('.png', '.jpg')
        image.save(output, "JPEG", quality = 100)
    else:
        print('Invalid file format. Please try again.')

if __name__ == '__main__':
    main()
