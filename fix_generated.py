#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, re, sys

DIR = "../generated/cowboy"

OPERATIONS_RE = re.compile(r'(?<=(\[|,)\n)'
                           r'(?P<operation>\s+%%.+?\{<<"(?P<path>.+?)">>.+?\},?\n)'
                           r'(?=\s+(%%|\]))', flags=re.DOTALL)

REST_API_RE = re.compile(r'^(?P<start>.*?\[\n)(?P<operations>.*)$',
                         flags=re.DOTALL)


ordered_paths = []
with open('./paths/index.yaml', "r") as f:
    for line in f:
        if line.startswith('/') and line.endswith(':\n'):
            path = line.rstrip(':\n')
            ordered_paths.append(re.sub(r'{(.*?)}', ':\g<1>', path))


for n in os.listdir(DIR):
    with open(os.path.join(DIR, n), "r+") as f:
        # Fix multiline comments.
        lines = f.readlines()
        new_lines = []
        for line in lines:
            if '\\n' in line.rstrip():
                pos = line.find('%%')
                if pos >= 0:
                    parts = filter(lambda p: p, line[pos + 3:].rstrip().split('\\n'))
                    parts = map(lambda p: ' ' * pos + '%% ' + p + '\n', parts)
                    new_lines.extend(parts)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        lines = ''.join(new_lines)

        # Fix paths ordering
        file_beginning, operations = REST_API_RE.match(lines).groups()
        rest_routes = {rest_route.group('path'): rest_route.group('operation')
                       for rest_route
                       in OPERATIONS_RE.finditer(operations)}
        # import pdb; pdb.set_trace()
        operations = ''.join(rest_routes[path]
                             for path in ordered_paths
                             if path in rest_routes)

        lines = file_beginning + operations + '    ].\n'

        # Fix syntax and substitute invalid character sequences.
        lines = re.sub(r',(\s*[}\]\)])', '\g<1>', lines)
        lines = re.sub('\\&\\#39\\;', '\'', lines)
        lines = re.sub('\\&\\#x3D\\;\\&gt\\;', '=>', lines)
        lines = re.sub('\\&\\#x60\\;', '`', lines)

        # Write new file.
        f.seek(0)
        f.truncate()
        f.write(lines)
