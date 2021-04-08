
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
let s:async_jobs = []

" For async shell: Main
function! s:runInShell(cmd)
    call s:manageShellOutput()

    " Error if another async job is running
    if s:isAsyncJobRunning()
        echom "ERROR: Another job is already running"
        return
    endif

    " Start async job
    write
    let s:start_time = localtime()
    let l:arguments = [&shell, &shellcmdflag, a:cmd]
    let l:job = job_start(l:arguments, s:getShellOptions())
    call add(s:async_jobs, l:job)
endfunction

function! s:getShellOptions()
    let opts = {}
    let opts.close_cb = function('s:shellCloseHandler')
    let opts.callback = function('s:shellMessageHandler')
    "let opts.term_kill = 'term'
    "let opts.vertical = 'belowright'
    "let opts.norestore = 1
    "let opts.term_finish = 'open'
    "let opts.in_mode = 'nl'
    return opts
endfunction

function! s:shellMessageHandler(channel, msg)
    if !s:isShellBufferExists()
        return
    endif
    
    " for whether to scroll
    let l:at_eof = s:isShellScrollAtEof()

    call appendbufline(s:output_bufname, '$', a:msg)

    if l:at_eof
        call s:scrollShellToBottom()
    end
endfunction

function! s:shellCloseHandler(channel)
    " for whether to scroll
    let l:at_eof = s:isShellScrollAtEof()

    call s:reportTiming()

    if !s:isAsyncJobRunning()
        call appendbufline(s:output_bufname, '$', '[[Note: job was killed]]')
    endif

    let s:async_jobs = []

    if l:at_eof
        call s:scrollShellToBottom()
    end
endfunction!

function! s:reportTiming()
    let l:duration = localtime() - s:start_time
    let l:interval = 'seconds'

    if l:duration > 60
        let l:duration /= 60.0
        let l:duration = round(l:duration * 100) / 100
        let l:interval = 'minute(s)'
    endif

    if l:duration > 60 || !s:isShellVisible()
        !python3 ~/my/dotfiles/utils/slackit.py 'vim py'
    endif

    call appendbufline(s:output_bufname, '$', '')
    call appendbufline(s:output_bufname, '$', '[[Finished in '.string(l:duration).' '.l:interval.']]')
endfunction

function! s:manageShellOutput()
    " 1 if shell is not visible
        " 1A if no job => show shell + clean output
        " 1B if job is running => show shell
    " 2 if shell is visible (assume buffer exists)
        " 2A if no job => clean output
        " 2B if job is running => do nothing

    " For 1A + 1B
    call s:showShellOutput()

    " For 1A + 2A
    call s:cleanShellOutput()
endfunction

function! s:showShellOutput()
    if s:isShellVisible()
        return
    endif

    " Create buf
    if !s:isShellBufferExists()
        call bufadd(s:output_bufname)
        call bufload(s:output_bufname)
    endif

    " Load buf into win
    let l:currWinId = win_getid()
    silent exe 'vertical botright sbuffer '.s:output_bufname
    call win_gotoid(l:currWinId)

    " Settings for this special buffer
    call setbufvar(s:output_bufname, '&buftype', 'nofile')
    call setbufvar(s:output_bufname, '&swapfile', 0)
    call setbufvar(s:output_bufname, '&foldlevel', 99)
    "call setbufvar(s:output_bufname, '&foldenable', 0)
    "call setbufvar(s:output_bufname, '&foldlevel', 99)
    "call setbufvar(s:output_bufname, '&buflisted', 0)
    "call setbufvar(s:output_bufname, '&bufhidden', 'wipe')
    "call setbufvar(s:output_bufname, '&bufhidden', 'hide')
endfunction

function! s:cleanShellOutput()
    if s:isAsyncJobRunning()
        return
    endif

    call deletebufline(s:output_bufname, 1, '$')

    call appendbufline(s:output_bufname, '$', '[[Initiated]]')
    call appendbufline(s:output_bufname, '$', '')

    call s:scrollShellToBottom()
endfunction


# For async shell: Helper functions
function! s:isAsyncJobRunning()
    return len(s:async_jobs) != 0
endfunction

function! s:isShellVisible()
    return s:getShellWinId() != -1
endfunction

function! s:isShellBufferExists()
    return bufnr(s:output_bufname) != -1
endfunction

function! s:getShellWinId()
    return bufwinid(s:output_bufname)
endfunction

function! s:scrollShellToBottom()
    call win_execute(s:getShellWinId(), 'call cursor("$", 0) | redraw')
endfunction

function! s:isShellScrollAtEof()
    return (line('.', s:getShellWinId()) == line('$', s:getShellWinId()))
endfunction


" For specificallly running python in shell
function! s:getPythonCommand()
    let l:cmd = ''

    " Switch dir if sketch.py
    let l:venv_dir = getcwd()
    let l:current_filename = expand('%:p')
    if l:current_filename == g:sketch_filename
        let l:venv_dir = g:dir_dotfiles . 'utils'
    endif

    " Source venv, if possible
    let l:venv_file = l:venv_dir.'/.venv/bin/activate'
    if filereadable(l:venv_file)
        let l:cmd .= 'source '.l:venv_file.' && '
    endif

    " Add current file
    let l:cmd_to_run_python = 'python3 -B '.l:current_filename
    let l:cmd .= l:cmd_to_run_python

    return l:cmd
endfunction

function! s:executePython()
    call s:runInShell(s:getPythonCommand())
endfunction


function! StopJob()
    for l:job in s:async_jobs
        echom 'Stopping job: '.l:job
        call job_stop(l:job)
    endfor

    let s:async_jobs = []
endfunction

command! StopJob call StopJob()

