"""No-UI Kitty kitten: calculate the pixel size of a requested terminal grid."""
import json

from kittens.tui.handler import result_handler


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    from kitty.fast_data_types import cell_size_for_window, viewport_for_window

    window = boss.window_id_map[target_window_id]
    columns, rows = map(int, args[1:])
    cell_width, cell_height = cell_size_for_window(window.os_window_id)
    central, _, width, height, *_ = viewport_for_window(window.os_window_id)
    spacing = {
        edge: window.effective_padding(edge) + window.effective_margin(edge)
        for edge in ('left', 'top', 'right', 'bottom')
    }
    return json.dumps({
        'width': columns * cell_width + spacing['left'] + spacing['right'] + width - central[4],
        'height': rows * cell_height + spacing['top'] + spacing['bottom'] + height - central[5],
    })
