
public static class OrderHelper
{
    public static (bool IsValid, string Message) ValidateOrder(Order? order)
    {
        Console.WriteLine("hello world");
        if (order == null)
            return (false, "Order is empty");
        
        if (string.IsNullOrWhiteSpace(order.CustomerEmail))
            return (false, "Customer Email is empty");
        
        if (string.IsNullOrWhiteSpace(order.CustomerName))
            return (false, "Customer Name is empty");
        
        if (order.Items == null || !order.Items.Any())
            return (false, "Order does not contain any Items");
        
        foreach (OrderItem item in order.Items)
        {
            if (string.IsNullOrWhiteSpace(item.ItemId))
                return (false, "ItemId is Empty");
            if (item.Quantity <= 0)
                return (false, "Item quantity is less than 1");
        }
        return (true, string.Empty);
    }
}