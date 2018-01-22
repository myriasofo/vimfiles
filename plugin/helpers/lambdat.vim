" (2018/1/21) I never use this but I should!

function! Lambdat(cmd)
    update
    let path = expand('%:h')
    let terminalCommand = 'lambdat ' . a:cmd . ' ' . path
    call ExecuteInShell(terminalCommand, 'right')
endfunction


command! -nargs=1 Lambdat call Lambdat(<f-args>)

