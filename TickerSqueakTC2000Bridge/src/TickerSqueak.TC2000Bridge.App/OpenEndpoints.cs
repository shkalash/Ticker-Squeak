using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using System.Text.RegularExpressions;

namespace TickerSqueak.TC2000Bridge.App
{
	public static class OpenEndpoints
	{
		private sealed class OpenRequest
		{
			[JsonPropertyName("symbol")]
			[Required]
			public string Symbol { get; set; } = string.Empty;
		}

		public static void Map(IEndpointRouteBuilder endpoints, TC2000Controller controller)
		{
			endpoints.MapPost("/tc2000/open", async (HttpRequest req) =>
			{
				OpenRequest? payload;
				try
				{
					payload = await req.ReadFromJsonAsync<OpenRequest>();
				}
				catch
				{
					return Results.Json(new { error = "Invalid JSON" }, statusCode: StatusCodes.Status400BadRequest);
				}
				if (payload == null || string.IsNullOrWhiteSpace(payload.Symbol))
				{
					return Results.Json(new { error = "Missing symbol" }, statusCode: StatusCodes.Status400BadRequest);
				}
				var symbol = payload.Symbol.Trim().ToUpperInvariant();
				if (symbol.Length > 20 || !Regex.IsMatch(symbol, @"^[A-Z0-9\-.]+$"))
				{
					return Results.Json(new { error = "Invalid symbol" }, statusCode: StatusCodes.Status400BadRequest);
				}

				if (!controller.IsTC2000Running())
				{
					return Results.Json(new { error = "TC2000 is not running" }, statusCode: StatusCodes.Status503ServiceUnavailable);
				}
				var focused = await controller.FocusAsync();
				if (!focused)
				{
					return Results.Json(new { error = "Failed to focus TC2000" }, statusCode: StatusCodes.Status500InternalServerError);
				}
				var typed = await controller.TypeSymbolAsync(symbol);
				if (!typed)
				{
					return Results.Json(new { error = "Failed to type symbol" }, statusCode: StatusCodes.Status500InternalServerError);
				}
				return Results.Json(new { ok = true }, statusCode: StatusCodes.Status200OK);
			});
		}
	}
}
