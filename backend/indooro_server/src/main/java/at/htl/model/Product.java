package at.htl.model;

import com.fasterxml.jackson.annotation.JsonProperty;

public class Product {

    @JsonProperty("id")
    private Integer id;

    @JsonProperty("name")
    private String name;

    @JsonProperty("price")
    private Double price;

    @JsonProperty("layoutCode")
    private String layoutCode;

    @JsonProperty("storeId")
    private String storeId;

    @JsonProperty("storeCode")
    private String storeCode;

    public Product() {
    }

    public Product(Integer id, String name, Double price, String layoutCode) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.layoutCode = layoutCode;
    }

    public Product(Integer id, String name, Double price, String layoutCode, String storeId, String storeCode) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.layoutCode = layoutCode;
        this.storeId = storeId;
        this.storeCode = storeCode;
    }

    // Getters and Setters
    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }

    public String getLayoutCode() {
        return layoutCode;
    }

    public void setLayoutCode(String layoutCode) {
        this.layoutCode = layoutCode;
    }

    public String getStoreId() {
        return storeId;
    }

    public void setStoreId(String storeId) {
        this.storeId = storeId;
    }

    public String getStoreCode() {
        return storeCode;
    }

    public void setStoreCode(String storeCode) {
        this.storeCode = storeCode;
    }
}
