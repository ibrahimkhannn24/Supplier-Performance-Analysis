# Supplier Performance Analysis
This project focuses on analyzing and visualizing supplier performance and order history metrics using SQL and Python. The goal is to clean, preprocess, and analyze data from 17k+ records to gain actionable insights into supplier efficiency, defect rates, and cost optimization.

## Project Highlights
1. Data Cleaning and Transformation:
      - Processed two large datasets (supplier_performance with 5,000 rows and order_history with 12,000 rows) riddled with missing, inconsistent, and erroneous values.
      - Applied supplier-specific and global averages for imputation, removed irreparable rows, and standardized categorical data.

2. Advanced Analysis:
      - Calculated key metrics:
          - Supplier-level: On-time delivery rates, defect rates, total units delivered, and costs.
          - Regional-level: Best and worst-performing regions.
      - Identified top suppliers and trends in performance over time.
    
3. Complex Visualizations:
      - Created detailed plots using Matplotlib and Seaborn:
          - Trend analysis for delivery performance, defect rates, and cost fluctuations.
          - Regional comparisons through bar charts and scatter plots.
          - Correlation heatmaps revealing weak relationships between metrics.

4. Key Insights:
      - Highlighted top-performing suppliers and their metrics for strategic decision-making.
          - Identified North America as the most efficient region and provided insights into regional inefficiencies.
          - Analyzed cost and defect rate fluctuations, uncovering trends and potential external factors.
