
function! ExecuteCurrentFile()
    let winPrev = win_getid()
    update
    
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

    else
        echom 'ScoutKey: Filetype not supported for RunCode()'
    endif

    "elseif &filetype == 'stata'
    "elseif &filetype == 'r'
    "elseif &filetype == 'tex'
    "elseif &filetype == 'java'
    "elseif &filetype == 'cpp'

    call win_gotoid(winPrev)
endfunction

function! ExecuteInShell(cmd, direction)
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

function! s:executePython()
    try
        call ExecuteInShell('python3 %', 'right')
    catch
        call ExecuteInShell('python2 %', 'right')
    endtry
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


"command! -complete=shellcmd -nargs=+ Shell call ExecuteInShell(<q-args>)

