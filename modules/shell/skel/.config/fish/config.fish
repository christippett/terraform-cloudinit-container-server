if status is-interactive
    # Enable ASDF
    if test -e "$ASDF_DIR/asdf.fish"
        source "$ASDF_DIR/asdf.fish"
        asdf install
    end

    if ! test -e "$HOME/.config/fish/completions/asdf.fish" && test -e "$ASDF_DIR/completions/asdf.fish"
        mkdir -p "$HOME/.config/fish/completions"
        ln -fs "$ASDF_DIR/completions/asdf.fish" "$HOME/.config/fish/completions/asdf.fish"
    end

    # Enable Fisher
    if ! functions -q fisher
        curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
        fisher install jorgebucaran/hydro
    end
end
