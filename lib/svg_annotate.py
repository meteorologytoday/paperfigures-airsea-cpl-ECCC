import cairo
import xarray as xr
import numpy as np
import argparse
from pathlib import Path


if __name__ == "main":

    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('--input-file', type=str, help='Input svg filename.', required=True)
    parser.add_argument('--output-file', type=str, help='Output svg filename.', required=True)
    parser.add_argument('--thumbnail-numbering', type=int, help='The numbering. Starting with 1.', required=True)
    parser.add_argument('--thumbnail-numbering-style', type=str, help='The numbering style. It can be `alphabet`, `numeric`.', default="alphabet")
    parser.add_argument('--location-x', type=float, help='The location in fraction of x.', default=0.5)
    parser.add_argument('--location-6', type=float, help='The location in fraction of y.', default=0.9)
args = parser.parse_args()

    print(args)

    with cairo.SVGSurface("example.svg", 200, 200) as surface:
        context = cairo.Context(surface)
        x, y, x1, y1 = 0.1, 0.5, 0.4, 0.9
        x2, y2, x3, y3 = 0.6, 0.1, 0.9, 0.5
        context.scale(200, 200)
        context.set_line_width(0.04)
        context.move_to(x, y)
        context.curve_to(x1, y1, x2, y2, x3, y3)
        context.stroke()
        context.set_source_rgba(1, 0.2, 0.2, 0.6)
        context.set_line_width(0.02)
        context.move_to(x, y)
        context.line_to(x1, y1)
        context.move_to(x2, y2)
        context.line_to(x3, y3)
        context.stroke()
