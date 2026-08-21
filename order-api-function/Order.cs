public class Order
{
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public List<OrderItem> Items { get; set; } = [];
    public decimal TotalAmount { get; set; }
    public DateTime OrderDate { get; set; }
}

public class OrderItem
{
    public string ItemId { get; set; } = string.Empty;
    public int Quantity { get; set; }
}