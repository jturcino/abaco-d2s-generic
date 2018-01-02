#!/usr/bin/env python

from subprocess import Popen
from os import listdir
from re import search
from agavepy.actors import get_context, get_client

def get_vars_env(agave_context):
    '''Checks that MSG and outdir are present as
    context variables and returns their values'''
    required_keyset = set(['message_dict', 'outdir'])
    keyset = set(dict(agave_context).keys())
    assert required_keyset.issubset(keyset), 'Context is missing required keys (MSG, outdir): {}'.format(dict(agave_context).keys())
    return [ agave_context[x] for x in required_keyset ]

def get_vars_json(agave_context):
    '''Checks that container and outdir are present
    in message_dict and returns their values'''
    mdict = context.message_dict
    required_keyset = set(['container', 'outdir'])
    keyset = set(mdict.keys())
    assert required_keyset.issubset(keyset), 'Context is missing required keys (MSG, outdir): {}'.format(mdict.keys())
    return [ mdict[x] for x in required_keyset ]

def get_vars(agave_context):
    '''Returns container and outdir variables'''
    # check if passed as JSON
    if type(context.message_dict) is dict:
        c, o = get_vars_json(agave_context)
    else:
        c, o = get_vars_env(agave_context)
    return (c, o)

if __name__ == '__main__':

    # get context and client
    context = get_context()
    ag = get_client()

    # container, agave system, and path to outdir 
    container, outdir = get_vars(context)

    # execute d2s with bash
    d2s_cmd = 'sudo bash /docker2singularity.sh {}'.format(container)
    process = Popen(d2s_cmd.split()).wait()
    assert int(process) == 0, 'd2s command finished with non-zero status: {}'.format(str(process))

    # find image file produced
    files = ' '.join(listdir('/output'))
    regex = container.replace('/', '_').replace(':', '_')+'-[0-9]{4}-[0-9]{2}-[0-9]{2}-\w{12}\.img'
    img_search = search(regex, files)
    assert img_search is not None, 'Image for container {} not found in output files: {}'.format(container, files)
    img = '/output/'+str(img_search.group(0))

    # move file via work mount
    filename = container.split('/')[-1].replace(':', '_')+'.img'
    mv_cmd = 'bash /move-image.sh {} {} {}'.format(img, filename, outdir) 
    process = Popen(mv_cmd.split()).wait()
    assert int(process) == 0, 'Move command finished with non-zero status: {}'.format(str(process))

    # rmi container
    cleanup_cmd = 'sudo bash /cleanup.sh {}'.format(container)
    process = Popen(cleanup_cmd.split()).wait()
    assert int(process) == 0, 'Cleanup command finished with non-zero status: {}'.format(str(process))
