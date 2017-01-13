using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using MongoDB.Bson.Serialization.Attributes;

namespace Products.Models
{
    public class Products
    {
        [BsonElement("_id")]
        public int ProductId { get; set; }
        public string ProductName { get; set; }
        public int Price { get; set; }
        public string Category { get; set; }

       
    }
}
