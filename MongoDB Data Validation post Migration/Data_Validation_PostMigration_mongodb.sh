#!/bin/bash
#===============================================================================#
#Shell Script to Compare MongoDB Data                   Subrahmanyam Karri      #
#Mongo Dtaa verification after Migration                Sr DataArchitect        #
#On-Prem to Azure                                   subrahmanyeswarao@gmail.com #
#===============================================================================#
# On-premises MongoDB connection URI (adjust with actual host, port, and db-name)
ON_PREM_URI="mongodb://<on-prem-db-host>:<port>/<db-name>"
ON_PREM_DB="<db-name>"

# MongoDB on Azure VM connection URI (adjust with actual host, port, and db-name)
AZURE_URI="mongodb://<azure-db-host>:<port>/<db-name>"
AZURE_DB="<db-name>"

# Get list of collections from both databases
ON_PREM_COLLECTIONS=$(mongo $ON_PREM_URI --quiet --eval "db.getCollectionNames()")
AZURE_COLLECTIONS=$(mongo $AZURE_URI --quiet --eval "db.getCollectionNames()")

# Function to compare document count
compare_document_count() {
    local collection=$1
    # Get document count from both databases
    ON_PREM_COUNT=$(mongo $ON_PREM_URI --quiet --eval "db.$collection.countDocuments()")
    AZURE_COUNT=$(mongo $AZURE_URI --quiet --eval "db.$collection.countDocuments()")
    
    echo "Comparing document count for collection '$collection'..."
    if [ "$ON_PREM_COUNT" -eq "$AZURE_COUNT" ]; then
        echo "MATCH: Document count for '$collection' is the same ($ON_PREM_COUNT)."
    else
        echo "MISMATCH: Document count for '$collection' differs (On-prem: $ON_PREM_COUNT, Azure: $AZURE_COUNT)."
    fi
}

# Function to compare data (limited to first 10 documents for efficiency)
compare_data() {
    local collection=$1
    echo "Comparing data for collection '$collection'..."
    
    # Extract first 10 documents from both databases
    ON_PREM_DATA=$(mongo $ON_PREM_URI --quiet --eval "db.$collection.find({}).limit(10).toArray()")
    AZURE_DATA=$(mongo $AZURE_URI --quiet --eval "db.$collection.find({}).limit(10).toArray()")
    
    # Compare the data directly
    if [ "$ON_PREM_DATA" == "$AZURE_DATA" ]; then
        echo "MATCH: Data for '$collection' is identical."
    else
        echo "MISMATCH: Data for '$collection' differs."
        echo "On-premises data: $ON_PREM_DATA"
        echo "Azure data: $AZURE_DATA"
    fi
}

# Function to compare indexes
compare_indexes() {
    local collection=$1
    echo "Comparing indexes for collection '$collection'..."
    
    # Get indexes from both databases
    ON_PREM_INDEXES=$(mongo $ON_PREM_URI --quiet --eval "db.$collection.getIndexes()")
    AZURE_INDEXES=$(mongo $AZURE_URI --quiet --eval "db.$collection.getIndexes()")
    
    # Compare indexes
    if [ "$ON_PREM_INDEXES" == "$AZURE_INDEXES" ]; then
        echo "MATCH: Indexes for '$collection' are identical."
    else
        echo "MISMATCH: Indexes for '$collection' differ."
        echo "On-premises indexes: $ON_PREM_INDEXES"
        echo "Azure indexes: $AZURE_INDEXES"
    fi
}

# Iterate through collections and compare data
for collection in $ON_PREM_COLLECTIONS; do
    if [[ "$AZURE_COLLECTIONS" == *"$collection"* ]]; then
        # Compare document count
        compare_document_count $collection
        
        # Compare data (optional: can limit to the first N documents)
        compare_data $collection
        
        # Compare indexes
        compare_indexes $collection
        
        echo "================================="
    else
        echo "Collection '$collection' not found in Azure."
    fi
done

# Check for collections in Azure that do not exist in On-premises
for collection in $AZURE_COLLECTIONS; do
    if [[ "$ON_PREM_COLLECTIONS" != *"$collection"* ]]; then
        echo "Collection '$collection' found in Azure but not in On-premises."
    fi
done

echo "Comparison completed."
