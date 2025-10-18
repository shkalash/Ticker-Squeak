using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Windows.Forms;

namespace TickerSqueak.TC2000Bridge.App
{
	public partial class MainForm : Form
	{
		private readonly SettingsService _settings;
		private readonly TC2000Controller _controller;
		private readonly WebHostManager _host;
		private readonly TrayIcon _tray;

		private bool _minimizeToTray = true;
		private bool _startMinimized;
		private bool _isExiting;
		private int _savedPort;

		public MainForm()
		{
			InitializeComponent();

			_settings = new SettingsService();
			_controller = new TC2000Controller(_settings);
			_host = new WebHostManager(_settings, _controller);
			_tray = new TrayIcon();
			_tray.OpenRequested += (s, e) => RestoreFromTray();
			_tray.QuitRequested += async (s, e) => { _isExiting = true; Hide(); await _host.StopAsync(); _tray.Dispose(); Application.Exit(); };

			Application.ApplicationExit += (_, __) =>
			{
				try { _host.StopAsync().GetAwaiter().GetResult(); } catch { }
				try { _tray.Dispose(); } catch { }
			};

			var cfg = _settings.Load();
			_savedPort = cfg.Port;
			numPort.Value = Math.Min(Math.Max(cfg.Port, 1024), 65535);
			chkStartMin.Checked = cfg.StartMinimized;
			_startMinimized = cfg.StartMinimized;
			btnSave.Enabled = false; // disabled until port changes

			// Set form icon explicitly from embedded icon (ensures title bar + taskbar)
			try
			{
				this.Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
			}
			catch { }

			// Wire UI events
			numPort.ValueChanged += (_, __) => btnSave.Enabled = (int)numPort.Value != _savedPort;
			chkStartMin.CheckedChanged += chkStartMin_CheckedChanged;

			this.Shown += async (_, __) =>
			{
				if (_startMinimized)
				{
					WindowState = FormWindowState.Minimized;
					Hide();
				}
				await _host.StartAsync((int)numPort.Value);
				UpdateStatus();
			};

			UpdateStatus();
		}

		private void chkStartMin_CheckedChanged(object? sender, EventArgs e)
		{
			// Auto-save StartMinimized only
			var cfg = _settings.Load();
			cfg.StartMinimized = chkStartMin.Checked;
			_startMinimized = cfg.StartMinimized;
			_settings.Save(cfg);
		}

		private void UpdateStatus(string? extra = null)
		{
			var ip = GetLocalIPv4() ?? "0.0.0.0";
			var state = _host.IsRunning ? $"Running on {ip}:{_host.Port}" : "Stopped";
			lblStatus.Text = string.IsNullOrWhiteSpace(extra) ? state : $"{state} — {extra}";
			_tray.SetTooltip(state);
			UpdateStartStopButtons();
		}

		private void UpdateStartStopButtons()
		{
			btnStart.Enabled = !_host.IsRunning;
			btnStop.Enabled = _host.IsRunning;
		}

		private static string? GetLocalIPv4()
		{
			try
			{
				foreach (var ni in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
				{
					if (ni.OperationalStatus != System.Net.NetworkInformation.OperationalStatus.Up) continue;
					var ipProps = ni.GetIPProperties();
					foreach (var ua in ipProps.UnicastAddresses)
					{
						if (ua.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
							return ua.Address.ToString();
					}
				}
			}
			catch { }
			return null;
		}

		private async void btnStart_Click(object sender, EventArgs e)
		{
			await _host.StartAsync((int)numPort.Value);
			UpdateStatus();
		}

		private async void btnStop_Click(object sender, EventArgs e)
		{
			await _host.StopAsync();
			UpdateStatus();
		}

		private async void btnSave_Click(object sender, EventArgs e)
		{
			var cfg = _settings.Load();
			var newPort = (int)numPort.Value;
			cfg.Port = newPort;
			cfg.StartMinimized = chkStartMin.Checked; // keep current value
			_startMinimized = cfg.StartMinimized;
			_settings.Save(cfg);
			_savedPort = newPort;
			btnSave.Enabled = false;
			if (_host.IsRunning && _host.Port != newPort)
			{
				await _host.RestartAsync(newPort);
			}
			UpdateStatus("Settings saved");
		}

		private async void btnTest_Click(object sender, EventArgs e)
		{
			var symbol = (txtSymbol.Text ?? "").Trim();
			if (string.IsNullOrWhiteSpace(symbol)) { UpdateStatus("Symbol required"); return; }
			var launched = await _controller.LaunchIfNeededAsync();
			if (!launched) { UpdateStatus("TC2000 not running"); return; }
			var focused = await _controller.FocusAsync();
			if (!focused) { UpdateStatus("Failed to focus TC2000"); return; }
			var typed = await _controller.TypeSymbolAsync(symbol);
			UpdateStatus(typed ? $"Typed {symbol}" : "Failed to type symbol");
		}

		private void btnHealth_Click(object sender, EventArgs e)
		{
			var ip = GetLocalIPv4() ?? "127.0.0.1";
			var url = $"http://{ip}:{(int)numPort.Value}/health";
			try { Process.Start(new ProcessStartInfo { FileName = url, UseShellExecute = true }); } catch { }
		}

		private void MainForm_Resize(object? sender, EventArgs e)
		{
			if (!_isExiting && _minimizeToTray && WindowState == FormWindowState.Minimized)
			{
				Hide();
			}
		}

		private void RestoreFromTray()
		{
			Show();
			WindowState = FormWindowState.Normal;
			Activate();
		}

		private async void MainForm_FormClosing(object? sender, FormClosingEventArgs e)
		{
			_isExiting = true;
			try { await _host.StopAsync(); } catch { }
			try { _tray.Dispose(); } catch { }
		}
	}
}
