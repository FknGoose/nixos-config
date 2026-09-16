{ config, lib, pkgs, inputs, ... }:
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "yazi.desktop";

      "application/pdf" = "zen-beta.desktop";
      "text/html" = "zen-beta.desktop";
      "application/xhtml+xml" = "zen-beta.desktop";
      "x-scheme-handler/http" = "zen-beta.desktop";
      "x-scheme-handler/https" = "zen-beta.desktop";
      "x-scheme-handler/about" = "zen-beta.desktop";
      "x-scheme-handler/unknown" = "zen-beta.desktop";

      "application/msword" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-word.document.macroenabled.12" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.text-template" = "onlyoffice-desktopeditors.desktop";
      "application/rtf" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-excel.sheet.macroenabled.12" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.spreadsheet-template" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.template" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.slideshow" =
        "onlyoffice-desktopeditors.desktop";
      "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";

      "image/png" = "swayimg.desktop";
      "image/jpeg" = "swayimg.desktop";
      "image/pjpeg" = "swayimg.desktop";
      "image/gif" = "swayimg.desktop";
      "image/webp" = "swayimg.desktop";
      "image/bmp" = "swayimg.desktop";
      "image/tiff" = "swayimg.desktop";
      "image/svg+xml" = "swayimg.desktop";
      "image/avif" = "swayimg.desktop";
      "image/heic" = "swayimg.desktop";
      "image/heif" = "swayimg.desktop";
      "image/x-icon" = "swayimg.desktop";
      "image/x-portable-anymap" = "swayimg.desktop";
      "image/x-portable-bitmap" = "swayimg.desktop";
      "image/x-portable-graymap" = "swayimg.desktop";
      "image/x-portable-pixmap" = "swayimg.desktop";

      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "video/x-ms-wmv" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/3gpp" = "mpv.desktop";
      "video/3gpp2" = "mpv.desktop";
      "video/mp2t" = "mpv.desktop";

      "audio/mpeg" = "mpv.desktop";
      "audio/mp3" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/vnd.wave" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/opus" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/webm" = "mpv.desktop";
      "audio/x-matroska" = "mpv.desktop";

      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
      "text/csv" = "nvim.desktop";
      "text/tab-separated-values" = "nvim.desktop";
      "text/css" = "nvim.desktop";
      "text/javascript" = "nvim.desktop";
      "text/x-c" = "nvim.desktop";
      "text/x-python" = "nvim.desktop";
      "text/x-shellscript" = "nvim.desktop";
      "application/json" = "nvim.desktop";
      "application/yaml" = "nvim.desktop";
      "application/xml" = "nvim.desktop";
      "application/x-yaml" = "nvim.desktop";
      "application/x-sh" = "nvim.desktop";
      "application/x-shellscript" = "nvim.desktop";

      "x-scheme-handler/tg" = "yukigram.desktop";
    };
  };
}
