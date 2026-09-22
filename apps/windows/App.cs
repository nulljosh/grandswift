// Windows shell in C#: a WPF window hosting the game in WebView2 (the Edge engine built into Windows).
using System;
using System.Windows;
using System.Windows.Input;
using Microsoft.Web.WebView2.Wpf;

namespace VancouverVice;

public class App : Application
{
    [STAThread]
    public static void Main() => new App().Run();

    protected override async void OnStartup(StartupEventArgs e)
    {
        var web = new WebView2();
        var win = new Window { Title = "Vancouver Vice", Width = 1280, Height = 800, WindowState = WindowState.Maximized, WindowStyle = WindowStyle.None, Content = web };
        win.KeyDown += (_, k) => { if (k.Key == Key.F11) win.WindowStyle = win.WindowStyle == WindowStyle.None ? WindowStyle.SingleBorderWindow : WindowStyle.None; };
        win.Show();
        await web.EnsureCoreWebView2Async();
        web.CoreWebView2.Settings.UserAgent += " VancouverViceApp";
        web.CoreWebView2.Navigate("https://vancouvervice.heyitsmejosh.com/play.html");
    }
}
