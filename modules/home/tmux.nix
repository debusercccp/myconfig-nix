{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    
    terminal = "screen-256color";
    baseIndex = 1;
    prefix = "C-a";
    escapeTime = 0;

    plugins = with pkgs.tmuxPlugins; [
      nord
      vim-tmux-navigator
      sensible
      resurrect
      continuum
    ];

    extraConfig = ''
      # ===== Appearance =====
      set -g status-position top
      set -g status-bg '#1a1b26'
      set -g status-fg '#c0caf5'
      set -g status-left ' [#S] '
      set -g status-right ' #h | %H:%M '
      set -g window-status-format ' #{window_index}:#{window_name} '
      set -g window-status-current-format ' #{window_index}:#{window_name} '
      set -g window-status-current-bg '#7aa2f7'
      set -g window-status-current-fg '#1a1b26'

      # ===== Mouse & Keyboard =====
      set -g mouse on
      set -g focus-events on
      setw -g mode-keys vi
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      bind-key -T copy-mode-vi 'C-v' send -X rectangle-toggle

      # ===== Navigation =====
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
      bind-key -n C-\\ if-shell "$is_vim" "send-keys C-\\\\" "select-pane -l"

      # ===== Window Management =====
      bind c new-window -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"
      bind x kill-pane
      bind X kill-window

      # ===== Session Management =====
      bind d detach-client
      bind C-s choose-session
      bind L list-sessions

      # ===== Copy/Paste =====
      bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "xclip -i -sel clipboard"
      bind ] paste-buffer

      # ===== Reload Config =====
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # ===== Continuum/Resurrect =====
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '60'
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-strategy-nvim 'session'
    '';
  };
}
