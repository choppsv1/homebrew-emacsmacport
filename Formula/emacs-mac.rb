class EmacsMac < Formula
  desc "GNU Emacs for Mac + extras (Based on YAMAMOTO Mitsuharu's Mac port)"
  homepage "https://github.com/choppsv1/emacs-mac"
  url "https://github.com/choppsv1/emacs-mac/archive/refs/tags/28.2-mac-1.3.tar.gz"
  version "28.2-mac-1.3"
  sha256 "da16fa21c99bdf5a00ccbf1e8d1ba9f7bdb89a8de631f9ca66550eb22c836877"
  license "GPL-3.0-or-later"

  head do
    url "https://github.com/choppsv1/emacs-mac.git", :branch => "add-new-notifications"
  end

  option "without-modules", "Build without dynamic modules support"
  option "without-starter", "Build without a starter script to start emacs GUI from CLI"

  option "with-native-comp", "Build without native compilation"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "awk" => :build
  depends_on "gnu-sed" => :build
  depends_on "gnu-tar" => :build
  depends_on "grep" => :build
  depends_on "make" => :build
  depends_on "coreutils" => :build
  depends_on "pkgconf" => :build
  depends_on "texinfo" => :build
  depends_on "xz" => :build

  depends_on "gnutls"
  depends_on "jansson"
  depends_on "little-cms2"
  depends_on "librsvg" => :recommended
  depends_on "libxml2" => :recommended
  depends_on "imagemagick" => :optional
  depends_on "mailutils" => :optional

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  # with nativecomp
  if build.with? "native-comp"
    fails_with :clang do
      cause "Can't use clang for nativecomp"
    end
    depends_on "libgccjit"
    depends_on "gcc" => :build
    depends_on "gmp" => :build
    depends_on "libjpeg" => :build
    depends_on "zlib" => :build
  end

  # patch for multi-tty support, see the following links for details
  # https://bitbucket.org/mituharu/emacs-mac/pull-requests/2/add-multi-tty-support-to-be-on-par-with/diff
  # https://ylluminarious.github.io/2019/05/23/how-to-fix-the-emacs-mac-port-for-multi-tty-access/
  # patch do
  #   url "https://raw.githubusercontent.com/choppsv1/homebrew-emacsmacport/main/patches/multi-tty-28.diff"
  #   sha256 "e5fc921fe979d08b1742eaeb0f933af48a536905cc27acbde5274dc4dd79bb85"
  # end

  patch do
    url "https://raw.githubusercontent.com/railwaycat/homebrew-emacsmacport/667f0efc08506facfc6963ac1fd1d5b9b777e094/patches/multi-tty-27.diff"
    sha256 "5a13e83e79ce9c4a970ff0273e9a3a07403cc07f7333a0022b91c191200155a1"
  end

  def install
    # Mojave uses the Catalina SDK which causes issues like
    # https://github.com/Homebrew/homebrew-core/issues/46393
    # https://github.com/Homebrew/homebrew-core/pull/70420
    ENV["ac_cv_func_aligned_alloc"] = "no" if MacOS.version == :mojave

    args = [
      "--disable-acl",
      "--disable-silent-rules",
      "--enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp",
      "--enable-mac-app=#{prefix}",
      "--infodir=#{info}/emacs",
      "--prefix=#{prefix}",
      "--with-gnutls",
      "--with-mac",
      "--with-xml2",
      "--with-xpm=ifavailable",
      "--without-x",
      "--without-dbus",
    ]
    args << "--with-imagemagick" if build.with? "imagemagick"
    args << "--with-modules" if build.with? "modules"
    args << "--without-pop" if build.with? "mailutils"
    args << "--with-rsvg" if build.with? "librsvg"

    args << "--with-native-compilation" if build.with? "native-comp"

    ENV.prepend_path "PATH", Formula["gnu-sed"].opt_libexec/"gnubin"

    system "./autogen.sh"

    File.write "lisp/site-load.el", <<~EOS
      (setq exec-path (delete nil
        (mapcar
          (lambda (elt)
            (unless (string-match-p "Homebrew/shims" elt) elt))
          exec-path)))
    EOS

    # export CC="gcc -I$(brew --prefix libgccjit)/include"; export CPATH=/opt/homebrew/bin/gcc-13; export LDFLAGS=-L$(brew --prefix libgccjit)/lib/gcc/current; export LIBRARY_PATH=$(brew --prefix libgccjit)/lib/gcc/current EMACSAPP=/opt/APP ; ./configure

    # Necessary for libgccjit library discovery
    #ENV["CC"] = "/usr/bin/gcc"
    ENV.append "CPATH", "-I#{Formula["libgccjit"].opt_include}" if build.with? "native-comp"
    ENV.append "LIBRARY_PATH", "#{Formula["libgccjit"].opt_lib}/gcc/current" if build.with? "native-comp"
    ENV.append "LDFLAGS", "-L#{Formula["libgccjit"].opt_lib}/gcc/current" if build.with? "native-comp"

    system "./configure", *args
    system "make -j 10"
    system "make", "install"
    prefix.install "NEWS-mac"

    # Follow Homebrew and don't install ctags from Emacs. This allows Vim
    # and Emacs and exuberant ctags to play together without violence.
    (bin/"ctags").unlink
    (share/man/man1/"ctags.1.gz").unlink

    if build.with? "starter"
      # Replace the symlink with one that starts GUI
      # alignment the behavior with cask
      # borrow the idea from emacs-plus
      (bin/"emacs").unlink
      (bin/"emacs").write <<~EOS
        #!/bin/bash
        exec #{prefix}/Emacs.app/Contents/MacOS/Emacs.sh "$@"
      EOS
    end
  end

  def caveats
    <<~EOS
      This is GNU Emacs based on YAMAMOTO Mitsuharu's "Mac port" additions and
      also included ones from Christian Hopps. This provides a native GUI
      support for Mac OS X 10.6 - 11.0. After installing, see README-mac and
      NEWS-mac in #{prefix} for the port details.

      Emacs.app was installed to:
        #{prefix}

      To link the application to default Homebrew App location:
        ln -s #{prefix}/Emacs.app /Applications
      Other ways please refer:
        https://github.com/railwaycat/homebrew-emacsmacport/wiki/Alternative-way-of-place-Emacs.app-to-Applications-directory

      If you are using Doom Emacs, be sure to run doom sync:
        ~/.emacs.d/doom sync

      For an Emacs.app CLI starter, see:
        https://gist.github.com/4043945
    EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
