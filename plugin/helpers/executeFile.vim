
function! ExecuteCurrentFile()
    if &filetype == 'haskell'
        call s:executeHaskell()

    elseif &filetype == 'javascript' || &filetype == 'javascript.jsx'
        call s:executeJavascript()

    elseif &filetype == 'python'
        call s:executePython()

    elseif &filetype == 'todo' && expand('%:t') == 'timeLog.to'
        call s:executeTimeLog()

    elseif &filetype == 'vim'
        call s:executeVimscript()

    elseif &filetype == 'ruby'
        call s:executeRuby()

    elseif &filetype == 'go'
        call s:executeGolang()

    else
        echom 'ScoutKey: Filetype not supported for RunCode()'
    endif

    "elseif &filetype == 'stata'
    "elseif &filetype == 'r'
    "elseif &filetype == 'tex'
    "elseif &filetype == 'java'
    "elseif &filetype == 'cpp'
endfunction

function! ExecuteInShell(cmd, direction)
    let winPrev = win_getid()
    update

    " Expand all vim symbols in cmd
    let cmd = join(map(split(a:cmd), 'expand(v:val)'))
    "let output_bufname = '"' . cmd . '"'
    "let output_bufname = fnameescape(cmd)
    "let winNum = bufwinnr('^'.cmd.'$')
    let output_bufname = "[Shell output"

    " If output win exists, switch. If not, create new
    let winNum = bufwinnr(output_bufname)
    if winNum != -1
        exe winNum.'wincmd w'
    else
        if a:direction == 'down'
            exe "belowright new " . output_bufname
        elseif a:direction == 'right'
            exe "belowright vs new " . output_bufname
        endif
    endif

    " Set options for this special win
    setlocal buftype=nowrite bufhidden=wipe noswapfile nonumber nofoldenable nobuflisted
    "setlocal filetype=shelloutput

    " Run cmd, paste output
    exe 'silent %!'.cmd

    " If going down, resize to fit output
    if a:direction == 'down'
        resize 5
        "exe 'resize '.line('$')
        "redraw
    endif

    call win_gotoid(winPrev)
endfunction


function! s:executeHaskell()
    let folder = expand('%:p:h')
    let buildFolder = folder . '/.build/'
    let executablePath = buildFolder . '/main'

    if !isdirectory(buildFolder)
        call mkdir(buildFolder)
    endif

    let compileCommand = 'ghc % -odir ' . buildFolder . ' -hidir ' . buildFolder . ' -o ' . executablePath
    let compileAndRun = compileCommand . ' && ' . executablePath
    silent! call ExecuteInShell(compileAndRun, 'right')
endfunction

function! s:executeJavascript()
    call ExecuteInShell('node %', 'right')
endfunction

function! s:executeRuby()
    call ExecuteInShell('ruby %', 'right')
endfunction

function! s:executeStata()
    ""silent! !start /min "C:\Users\Abe\Dropbox\Archives\static\stata-nppp\rundo.exe" "%:p"
    "let dir_runStata = 'C:\Users\Abe\Dropbox\Archives\static\stata-nppp\'
    "silent! exe '!start /min "'.dir_runStata.'rundo.exe" "%:p"'
endfunction

function! s:executeTimeLog()
    call ExecuteInShell('python ' . g:dir_dev . 'analyzeTimeLog/analyzeLog.py', 'right')
endfunction

function! s:executeVimscript()
    source %
endfunction

function! s:executeGolang()
    call ExecuteInShell('go run %', 'right')
endfunction


"command! -complete=shellcmd -nargs=+ Shell call ExecuteInShell(<q-args>)

  
let s:output_bufname = 'abe_shell'
let s:start_time = 0

function! s:runInShell(cmd)
    let s:start_time = localtime()

    let l:arguments = [&shell, &shellcmdflag, a:cmd]
    call job_start(l:arguments, s:getShellOptions())

    call s:setBufferForShellOutput()
endfunction

function! s:getShellOptions()
    let opts = {}
    let opts.close_cb = function('s:shellCloseHandler')
    "let opts.callback = function('s:messageHandler')
    let opts.callback = {channel, msg -> appendbufline(s:output_bufname, '$', msg) }
    ""let opts.term_kill = 'term'
    "let opts.vertical = 'belowright'
    ""let opts.norestore = 1
    ""let opts.term_finish = 'open'
    "call term_start(c, opts)
    "let l:options['in_mode'] = 'nl'
    return opts
endfunction

function! s:shellCloseHandler(channel)
    let duration = localtime() - s:start_time
    call appendbufline(s:output_bufname, '$', '')
    call appendbufline(s:output_bufname, '$', '[[Finished in '.l:duration.' seconds]]')
endfunction!

function! s:setBufferForShellOutput()
    let l:currWinId = win_getid()

    if bufnr(s:output_bufname) == -1
        exe 'vertical botright new '.s:output_bufname
        call setbufvar(s:output_bufname, '&foldenable', 0)
        call setbufvar(s:output_bufname, '&buftype', 'nofile')
        call setbufvar(s:output_bufname, '&swapfile', 0)
        call setbufvar(s:output_bufname, '&buflisted', 0)
        call setbufvar(s:output_bufname, '&bufhidden', 'wipe')
        "call setbufvar(s:output_bufname, '&relativenumber', 0)
    end

    call deletebufline(s:output_bufname, 1, '$')
    call appendbufline(s:output_bufname, '$', '[[Initiated]]')
    call appendbufline(s:output_bufname, '$', '')

    call win_gotoid(l:currWinId)
endfunction


function! s:getPythonCommand()
    let l:cmd = ''

    " Source venv, if possible
    let l:venv_file = getcwd().'/.venv/bin/activate'
    if filereadable(l:venv_file)
        let l:cmd .= 'source '.l:venv_file.' && '
    endif

    " Add current file
    let l:current_filename = expand('%:p')
    let l:cmd_to_run_python = 'python3 -B '.l:current_filename
    let l:cmd .= l:cmd_to_run_python

    return l:cmd
endfunction

function! s:executePython()
    call s:runInShell(s:getPythonCommand())
endfunction

