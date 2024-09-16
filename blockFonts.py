#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Time    : 9/15/24
# @Author  : luoolu
# @Github  : https://luoolu.github.io
# @Software: PyCharm
# @File    : test.py
from PIL import Image, ImageDraw, ImageFont
import sys
import time
import shutil


def text_to_ascii(text, font_path="DejaVuSans-Bold.ttf", font_size=18, threshold=128):
    # 创建字体对象
    try:
        font = ImageFont.truetype(font_path, font_size)
    except IOError:
        print(f"无法找到字体文件: {font_path}")
        sys.exit(1)

    # 创建一个临时图像用于计算文本的边界框
    dummy_img = Image.new('L', (1, 1), color=255)
    draw = ImageDraw.Draw(dummy_img)

    # 使用 textbbox 计算文本尺寸
    try:
        text_bbox = draw.textbbox((0, 0), text, font=font)
        text_width = text_bbox[2] - text_bbox[0]
        text_height = text_bbox[3] - text_bbox[1]
    except AttributeError:
        # 对于旧版本的 Pillow，使用 textsize
        text_width, text_height = draw.textsize(text, font=font)

    # 创建图像并绘制文本
    img = Image.new('L', (text_width, text_height), color=0)
    draw = ImageDraw.Draw(img)
    draw.text((0, 0), text, font=font, fill=255)

    # 转换图像为 ASCII
    pixels = img.load()
    ascii_str = ""
    for y in range(text_height):
        line = ""
        for x in range(text_width):
            if pixels[x, y] > threshold:
                line += "█"
            else:
                line += " "
        ascii_str += line + "\n"

    return ascii_str


def print_ascii_colored(ascii_art, color_code="\033[97m"):
    colored_ascii = f"{color_code}{ascii_art}\033[0m"
    print(colored_ascii)


def wrap_text(text, max_width):
    words = text.split()
    lines = []
    current_line = ""

    for word in words:
        if len(current_line + " " + word) <= max_width:
            if current_line:
                current_line += " " + word
            else:
                current_line = word
        else:
            lines.append(current_line)
            current_line = word

    if current_line:
        lines.append(current_line)

    return lines


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("用法: python3 text_to_blocks.py '模式' '您的文本' [字体路径]")
        print("模式: 'word' - 逐词打印, 'wrap' - 自动换行")
        sys.exit(1)

    mode = sys.argv[1]
    input_text = sys.argv[2]

    if len(sys.argv) >= 4:
        font_path = sys.argv[3]
    else:
        font_path = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"  # Ubuntu 默认字体路径

    if mode == "word":
        words = input_text.split()
        for word in words:
            ascii_art = text_to_ascii(word, font_path=font_path)
            print_ascii_colored(ascii_art)
            time.sleep(1)  # 延迟1秒，可根据需要调整
    elif mode == "wrap":
        # 获取终端宽度
        terminal_size = shutil.get_terminal_size((80, 20))
        terminal_width = terminal_size.columns

        # 估计每个字符的宽度（根据字体大小和字符）
        # 这里假设每个ASCII字符占用8个终端字符宽度（根据实际情况调整）
        ascii_char_width = 8
        max_chars_per_line = terminal_width // ascii_char_width

        # 分割文本为多行
        wrapped_lines = wrap_text(input_text, max_chars_per_line)

        for line in wrapped_lines:
            ascii_art = text_to_ascii(line, font_path=font_path)
            print_ascii_colored(ascii_art)
    else:
        # 默认整体打印
        ascii_art = text_to_ascii(input_text, font_path=font_path)
        print_ascii_colored(ascii_art)




