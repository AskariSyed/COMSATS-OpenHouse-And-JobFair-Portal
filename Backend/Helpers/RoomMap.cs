using CsvHelper.Configuration;
using JobFairPortal.DTOs;

namespace JobFairPortal.Helpers
{
    public class RoomMap : ClassMap<RoomBulkCreateDto>
    {
        public RoomMap()
        {
            Map(m => m.RoomName).Name("RoomName");
            Map(m => m.Capacity).Name("Capacity");
            Map(m => m.Status).Name("Status");
        }
    }
}
