bindkey '^w' autosuggest-execute
bindkey '^e' autosuggest-accept
bindkey '^u' autosuggest-toggle
bindkey '^L' vi-forward-word
bindkey '^k' up-line-or-search
bindkey '^j' down-line-or-search

function zvm_after_init() {
    # Completely remove ESC key bindings
    bindkey -M viins -r "^["
    bindkey -M vicmd -r "^["
}