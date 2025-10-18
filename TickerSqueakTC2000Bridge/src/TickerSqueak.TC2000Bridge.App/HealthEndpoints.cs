using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace TickerSqueak.TC2000Bridge.App
{
	public static class HealthEndpoints
	{
		public static void Map(IEndpointRouteBuilder endpoints, SettingsService settings, TC2000Controller controller, System.Func<int> getPort)
		{
			endpoints.MapGet("/health", () =>
			{
				var running = controller.IsTC2000Running();
				return Results.Json(new
				{
					ok = true,
					port = getPort(),
					tc2000Running = running,
					version = typeof(Program).Assembly.GetName().Version?.ToString() ?? "1.0.0"
				});
			});
		}
	}
}
