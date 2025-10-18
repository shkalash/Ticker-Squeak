using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace TickerSqueak.TC2000Bridge.App
{
	public sealed class WebHostManager
	{
		private IHost? _host;
		private CancellationTokenSource? _cts;

		private readonly SettingsService _settings;
		private readonly TC2000Controller _controller;

		public bool IsRunning => _host is not null;
		public int Port { get; private set; }

		public WebHostManager(SettingsService settings, TC2000Controller controller)
		{
			_settings = settings;
			_controller = controller;
			Port = settings.Load().Port;
		}

		public async Task StartAsync(int port)
		{
			if (_host is not null) return;
			Port = port;
			_cts = new CancellationTokenSource();

			_host = Host.CreateDefaultBuilder()
				.ConfigureServices(services =>
				{
					services.AddSingleton(_settings);
					services.AddSingleton(_controller);
					services.AddRouting();
				})
				.ConfigureWebHostDefaults(webBuilder =>
				{
					webBuilder.UseKestrel(options =>
					{
						options.ListenAnyIP(Port);
					});
					webBuilder.Configure(app =>
					{
						var env = app.ApplicationServices.GetRequiredService<IHostEnvironment>();
						if (env.IsDevelopment())
						{
							app.UseDeveloperExceptionPage();
						}
						app.UseRouting();
						app.UseEndpoints(endpoints =>
						{
							HealthEndpoints.Map(endpoints, _settings, _controller, () => Port);
							OpenEndpoints.Map(endpoints, _controller);
						});
					});
				})
				.Build();

			await _host.StartAsync(_cts.Token);
		}

		public async Task StopAsync()
		{
			if (_host is null) return;
			_cts?.Cancel();
			try { await _host.StopAsync(TimeSpan.FromSeconds(2)); } catch { }
			_host.Dispose();
			_host = null;
			_cts?.Dispose();
			_cts = null;
		}

		public async Task RestartAsync(int port)
		{
			await StopAsync();
			await StartAsync(port);
		}
	}
}
