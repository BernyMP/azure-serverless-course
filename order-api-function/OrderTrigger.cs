using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json;

namespace order_api_function;

public class OrderTrigger
{
    private readonly ILogger<OrderTrigger> _logger;

    public OrderTrigger(ILogger<OrderTrigger> logger)
    {
        _logger = logger;
    }

    [Function("OrderTrigger")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequest req)
    {
        _logger.LogInformation("Processing of the Order has started.");

        Order? order;
        try
        {
            order = await req.ReadFromJsonAsync<Order>();

        }
        catch (JsonException ex)
        {
            _logger.LogInformation($"Invalid JSON: {ex.Message}");
            return new BadRequestObjectResult(new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Invalid request body.",
                Detail = "Request body is not valid JSON."
            });
        }

        // Deconstruct the (bool, string) tuple returned by ValidateOrder into two variables.
        var (isValid, validationMessage) = OrderHelper.ValidateOrder(order);

        if (!isValid)
            return new BadRequestObjectResult(new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "Invalid request body",
                Detail = validationMessage
            });

        return new OkObjectResult("Order has been processed successfully");
    }
}
