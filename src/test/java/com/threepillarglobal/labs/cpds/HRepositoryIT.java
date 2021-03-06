package com.threepillarglobal.labs.cpds;

import com.threepillarglobal.labs.hbase.annotation.HColumn;
import com.threepillarglobal.labs.hbase.annotation.HColumnFamily;
import com.threepillarglobal.labs.hbase.annotation.HTable;
import com.threepillarglobal.labs.hbase.repository.HRepository;
import com.threepillarglobal.labs.hbase.util.HOperations;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import lombok.Data;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.client.HBaseAdmin;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.hadoop.hbase.HbaseTemplate;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

//used to test te functionality of HRepository
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = "classpath*:integrationTests-context.xml")
public class HRepositoryIT {

    @HTable(name = "hrepoit")
    @HColumnFamily(name = "df") //a default column table at class level
    @Data
    public static class Table {

        private static byte[] row = "row".getBytes();

        @HColumn
        private String id;
        @HColumnFamily
        private CFamily1 cf1 = new CFamily1();
        @HColumnFamily
        private CFamily1 cf11 = new CFamily1();
        //colum sfamily is defined at class level
        private CFamily2 cf2 = new CFamily2();

        @Data
        public static class CFamily1 {

            @HColumn(name = "col01")
            private String col01 = "value0";
            @HColumn(name = "col02")
            private String col02 = "value1";
        }

        @HColumnFamily(name = "cf2")
        @Data
        public static class CFamily2 {

            @HColumn(name = "col11")
            private String col11 = "value0";
            @HColumn(name = "col12")
            private String col12;
        }

    }

    @Resource(name = "hbaseConfiguration")
    private Configuration config;

    @Autowired
    private HbaseTemplate hBaseTemplate;

    @PostConstruct
    public void init() {
        tableRepo = new HRepository<Table>(Table.class, hBaseTemplate) {
        };
        cf1Repo = new HRepository<Table.CFamily1>(Table.class, hBaseTemplate) {
        };
        cf2Repo = new HRepository<Table.CFamily2>(Table.class, hBaseTemplate) {
        };
    }
    //repos
    private HRepository<Table> tableRepo;
    private HRepository<Table.CFamily1> cf1Repo;
    private HRepository<Table.CFamily2> cf2Repo;

    @Before
    public void setUp() throws IOException {
        HOperations.createTable(Table.class, new HBaseAdmin(config));
    }

    @After
    public void tearDown() throws IOException {
        HOperations.deleteTable(Table.class, new HBaseAdmin(config));
    }

    @Test
    public void save_and_read_a_table_object() {
        Table expected = new Table();
        tableRepo.save(Table.row, expected);
        Table actual = tableRepo.findOne(Table.row);
        System.out.println("EXPECTED=========================================");
        System.out.println(expected);
        System.out.println("ACTUAL===========================================");
        System.out.println(actual);
        Assert.assertEquals(expected, actual);
    }

    @Test
    public void save_a_column_family_field_annotated_should_do_nothing() {
        Assert.assertNull(cf1Repo.save(Table.row, new Table.CFamily1()));
    }

    @Test
    public void save_and_read_a_column_family_class_annotated_should_pass() {
        Table.CFamily2 expected = new Table.CFamily2();
        cf2Repo.save(Table.row, expected);
        Table.CFamily2 actual = cf2Repo.findOne(Table.row);
        System.out.println("EXPECTED=========================================");
        System.out.println(expected);
        System.out.println("ACTUAL===========================================");
        System.out.println(actual);
        Assert.assertEquals(expected, actual);
    }

    @Test
    public void save_and_read_multiple_table_objects() {
        Map<byte[], Table> map = generateTableEntities(10);
        tableRepo.save(map);
        List<Table> result = tableRepo.findAll();
        int i = 0;
        for (Table actual : result) {
            System.out.println("ACTUAL===========================================");
            System.out.println(actual);
            Assert.assertEquals("ID" + i, actual.getId());
            i++;
        }
    }

    @Test
    public void save_and_read_multiple_column_family_objects() {
        Map<byte[], Table.CFamily2> map = generateColumnFamilyEntities(10);
        cf2Repo.save(map);
        List<Table.CFamily2> result = cf2Repo.findAll();
        int i = 0;
        for (Table.CFamily2 actual : result) {
            System.out.println("ACTUAL===========================================");
            System.out.println(actual);
            Assert.assertEquals("val" + i, result.get(i).getCol11());
            i++;
        }
    }
    
    @Test
    public void save_and_read_slice_of_table_objects() {
        Map<byte[], Table> map = generateTableEntities(10);
        tableRepo.save(map);
        List<Table> result = tableRepo.findAll("row3".getBytes(),"row7".getBytes());
        Assert.assertEquals(4, result.size());
        Assert.assertEquals("ID5", result.get(2).getId());
    }
    
    @Test
    public void save_and_read_slice_of_column_family_objects() {
        Map<byte[], Table.CFamily2> map = generateColumnFamilyEntities(10);
        cf2Repo.save(map);        
        List<Table.CFamily2> result = cf2Repo.findAll("row3".getBytes(),"row7".getBytes());
        Assert.assertEquals(4, result.size());
        Assert.assertEquals("val5", result.get(2).getCol11());
    }
    
    @Test
    public void save_and_delete_one() {
        Table expected = new Table();
        tableRepo.save(Table.row, expected);
        tableRepo.delete(Table.row);
        List<Table> result = tableRepo.findAll();
        Assert.assertEquals(0, result.size());
    }
    
    @Test
    public void save_and_delete_iterable() {
        Map<byte[], Table> map = generateTableEntities(10);
        tableRepo.save(map);
        tableRepo.delete(map.keySet());
        List<Table> result = tableRepo.findAll();
        Assert.assertEquals(0, result.size());
    }
    
    @Test
    public void save_and_delete_all() {
        Map<byte[], Table> map = generateTableEntities(10);
        tableRepo.save(map);
        tableRepo.deleteAll();
        List<Table> result = tableRepo.findAll();
        Assert.assertEquals(0, result.size());
    }
    

    //##########################################################################
    private Map<byte[], Table> generateTableEntities(int size) {
        Map<byte[], Table> map = new HashMap<byte[], Table>();
        Table table;
        for (int i = 0; i < size; i++) {
            table = new Table();
            table.setId("ID" + i);
            map.put(("row" + i).getBytes(), table);
        }
        return map;
    }

    private Map<byte[], Table.CFamily2> generateColumnFamilyEntities(int size) {
        Map<byte[], Table.CFamily2> map = new HashMap<byte[], Table.CFamily2>();
        Table.CFamily2 cf;
        for (int i = 0; i < size; i++) {
            cf = new Table.CFamily2();
            cf.setCol11("val" + i);
            map.put(("row" + i).getBytes(), cf);
        }
        return map;
    }
}
