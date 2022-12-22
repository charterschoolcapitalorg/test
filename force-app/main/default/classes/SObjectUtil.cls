public class SObjectUtil {
    private static Integer idSequence = 1;

    public static String getIdFieldForReference(String referenceFieldPath) {
        return referenceFieldPath.endsWith('__r') ? referenceFieldPath.replaceAll('__r$', '__c') : referenceFieldPath + 'Id';
    }

    public static String getReferenceFieldForId(String idFieldPath) {
        return idFieldPath.endsWith('__c') ? idFieldPath.replaceAll('__c$', '__r') : idFieldPath.replaceAll('Id$', '');
    }

    public static String getFakeId(Schema.DescribeSObjectResult type) {
        String result = String.valueOf(idSequence++);
        return Id.valueOf(type.getKeyPrefix() + '0'.repeat(12-result.length()) + result);
    }

    public static Map<SObjectKey,List<SObject>> groupByKeys(List<SObject> sobs, List<String> fields) {
        Map<SObjectKey,List<SObject>> resultMap = new Map<SObjectKey,List<SObject>>();
        for (SObject sob: sobs) {
            SObjectKey key = keyFrom(sob, fields);
            List<SObject> vals = resultMap.get(key);
            if (vals == null) {
                vals = new List<SObject>();
            }
            vals.add(sob);
            resultMap.put(key, vals);
        }
        return resultMap;
    }

    public static Map<String,List<SObject>> groupBy(List<SObject> sobs, String field) {
        Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>();
        for (SObject sob: sobs) {
            String key = (String)getField(sob, field);
            List<SObject> vals = resultMap.get(key);
            if (vals == null) {
                vals = new List<SObject>();
            }
            vals.add(sob);
            resultMap.put(key, vals);
        }
        return resultMap;
    }

    public static Map<Id,List<SObject>> groupById(List<SObject> sobs, String field) {
        Map<Id,List<SObject>> resultMap = new Map<Id,List<SObject>>();
        Map<String,List<SObject>> resultMapByString = groupBy(sobs, field);
        for (Id key: resultMapByString.keySet()) {
            resultMap.put(key, resultMapByString.get(key));
        }
        return resultMap;
    }

    public static Set<Id> collectIds(List<SObject> source) {
        return new Map<Id,SObject>(source).keySet();
    }

    public static Set<Id> collectIds(List<SObject> source, SObjectField field) {
        return collectIds(source, field.getDescribe().getLocalName());
    }

    /**
     * Reads set values from given 'source' list and inserts them into the given 'result' list
     * @param result The list to insert the values into
     * @param source The list to retrieve values from
     * @param field The field to read values from
     */
    public static Set<Id> collectIds(List<SObject> source, String fieldName) {
        Set<Id> result = new Set<Id>();
        for(SObject record : source) {
            if(record != null) {
                result.add((Id)getField(record, fieldName));
            }
        }
        result.remove(null);
        return result;
    }

    public static SObjectKey keyFrom(SObject sob, List<String> fields) {
        return new SObjectKey(sob, fields);
    }

    public static SObjectKey keyFrom(List<Object> vals) {
        return new SObjectKey(vals);
    }

    public static Object getField(SObject record, String path) {
        return getField(record, path, false);
    }

    public static Object getField(SObject record, String path, Boolean isSObject) {
        if (record == null) {
            return null;
        }

        List<String> pathParts = path.split('[.]', 2);

        if (pathParts.size() == 1) {
            return isSObject ? record.getSObject(path) : record.get(path);
        }

        return getField(record.getSObject(pathParts[0]), pathParts[1], isSObject);
    }

    public static void setField(SObject record, String path, Object val) {
        List<String> pathParts = path.split('[.]', 2);

        if (pathParts.size() == 1) {
            record.put(path, val);
            return;
        }

        SObject nestedRecord = record.getSObject(pathParts[0]);
        if (nestedRecord == null) {
            SObjectField field = record.getSObjectType().getDescribe().fields.getMap().get(getIdFieldForReference(pathParts[0]));
            List<SObjectType> referenceToTypes = field.getDescribe().getReferenceTo();
            if (referenceToTypes.size() != 1) {
                throw new SObjectException('Polymorphic relationships are not compatible with setField');
            }
            nestedRecord = referenceToTypes.get(0).newSObject();
            record.putSObject(pathParts[0], nestedRecord);
        }

        setField(nestedRecord, pathParts[1], val);
    }

    public static List<SObject> getRecordsFromMap(Map<Id,SObject> recordMap, Set<Id> recordIds) {
        List<SObject> records = new List<SObject>();
        for (Id recordId: recordIds) {
            SObject record = recordMap.get(recordId);
            if (record != null) {
                records.add(record);
            }
        }
        return records;
    }

    public static Predicate whereNot(Predicate pred) {
        return new NotPredicate(pred);
    }

    public static Predicate whereFieldEquals(String field, Object value) {
        return new FieldEqualsValuePredicate(field, value);
    }

    public static Predicate whereFieldEquals(SObjectField field, Object value) {
        return whereFieldEquals(field.getDescribe().getLocalName(), value);
    }

    public static Predicate whereFieldIn(String field, Set<Id> ids) {
        return new IdFieldInSetPredicate(field, ids);
    }

    public static Predicate whereFieldIn(SObjectField field, Set<Id> ids) {
        return whereFieldIn(field.getDescribe().getLocalName(), ids);
    }

    public static Predicate whereFieldIn(String field, Set<String> ids) {
        return new StringFieldInSetPredicate(field, ids);
    }

    public static Predicate whereFieldIn(SObjectField field, Set<String> ids) {
        return whereFieldIn(field.getDescribe().getLocalName(), ids);
    }

    public static List<SObject> filterList(List<SObject> records, Set<Id> ids) {
        List<SObject> results = new List<SObject>();
        for (SObject record: records) {
            if (ids.contains(record.Id)) {
                results.add(record);
            }
        }
        return results;
    }

    public static List<SObject> filterList(List<SObject> records, Predicate pred) {
        if (records == null) {
            return null;
        }
        List<SObject> result = new List<SObject>();
        for (SObject record: records) {
            if (pred.matches(record)) {
                result.add(record);
            }
        }
        return result;
    }
    
    public static List<String> getFields(FieldSet fs) {
        List<String> fields = new List<String>();
        for (FieldSetMember fsm: fs.getFields()) {
            fields.add(fsm.getFieldPath());
        }
        return fields;
    }

    public static List<SObject> getChanged(List<SObject> oldList, List<SObject> newList, FieldSet fs) {
        return getChanged(oldList, newList, new Set<String>(SObjectUtil.getFields(fs)));
    }

    public static List<SObject> getChanged(List<SObject> oldList, List<SObject> newList, Set<String> fields) {
        Set<Id> changedIds = getChangedIds(oldList, newList, fields);
        return filterList(newList, changedIds);
    }

    public static Set<Id> getChangedIds(List<SObject> oldList, List<SObject> newList, FieldSet fs) {
        return getChangedIds(oldList, newList, new Set<String>(SObjectUtil.getFields(fs)));
    }

    public static Set<Id> getChangedIds(List<SObject> oldList, List<SObject> newList, Set<String> fields) {
        return getChangedIds(new Map<Id,SObject>(oldList), new Map<Id,SObject>(newList), fields);
    }

    public static Set<Id> getChangedIds(Map<Id,SObject> oldMap, Map<Id,SObject> newMap, Set<String> fields) {
        Set<Id> changedIds = new Set<Id>();

        oldMap = oldMap == null ? new Map<Id,SObject>() : oldMap;
        newMap = newMap == null ? new Map<Id,SObject>() : newMap;

        Set<Id> allIds = new Set<Id>();
        allIds.addAll(oldMap.keySet());
        allIds.addAll(newMap.keySet());
        allIds.remove(null);

        for (Id i: allIds) {
            SObject oldRecord = oldMap.get(i);
            SObject newRecord = newMap.get(i);

            if (oldRecord != null && newRecord != null && oldRecord !== newRecord) {
                for (String field: fields) {
                    Object oldVal = getField(oldRecord, field);
                    Object newVal = getField(newRecord, field);

                    if ((oldVal != null || newVal != null) && (oldVal == null || newVal == null || !oldVal.equals(newVal))) {
                        changedIds.add(i);
                        break;
                    }
                }
            }

            if (oldRecord == null || newRecord == null) {
                changedIds.add(i);
            }
        }

        return changedIds;
    }

    /**
     * Copy fields from a map into the provided target record.
     */
    public static void applyFields(SObject target, Map<String,Object> toMerge) {
        for (String field: toMerge.keySet()) {
            target.put(field, toMerge.get(field));
        }
    }

    /**
     * Copy fields from another SObject into the provided target record.
     */
    public static void applyFields(SObject target, SObject toMerge) {
        applyFields(target, toMerge.getPopulatedFieldsAsMap());
    }

    /**
     * Return an SObjectType for the corresponding object API name. This uses a
     * workaround which performs much better than a global describe operation.
     */
    public static SObjectType getSObjectType(String objectName) {
        return ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType();
    }

    /** 
     * Filters a set of IDs to the matching type.
     */
    public static Set<Id> filterIdsToType(Set<Id> ids, SObjectType type) {
        Set<Id> result = new Set<Id>();
        for (Id i: ids) {
            if (i != null && i.getSObjectType() == type) {
                result.add(i);
            }
        }
        return result;
    }

    /**
     * Generic SObject key class, can be used to identify SObjects by specific fields for use in Maps and Sets.
     */
    public class SObjectKey {
        private final List<Object> vals = new List<Object>();

        /**
         * Create a new SObject key from provided field values
         * @param vals  list of field values to create a key for
         */
        public SObjectKey(List<Object> vals) {
            this.vals.addAll(vals);
        }

        /**
         * Create a new SObject key from a given SObject instance and the specified fields
         * @param sob  SOBject record to create a key for
         * @param fields  List of fields to use to identify an object
         */
        public SObjectKey(SObject sob, List<String> fields) {
            // clone values so SObjectKey is immutable
            for (String field: fields) {
                this.vals.add(getField(sob, field));
            }
        }

        public Integer hashCode() {
            Integer hash = 3;
            for (Object val: this.vals) {
                if (val instanceof Id) {
                    val = String.valueOf(val); // convert Id to String because Id hashcode is broken
                }
                hash = hash * 7 + (val == null ? 0 : System.hashCode(val));
            }
            return hash;
        }

        public Boolean equals(Object o) {
            if (o === this) {
                return true;
            }
            if (!(o instanceof SObjectKey)) {
                return false;
            }
            SObjectKey that = (SObjectKey)o;
            if (this.vals.size() != that.vals.size()) {
                return false;
            }
            for (Integer i = 0; i < this.vals.size(); i++) {
                Object thisVal = this.vals.get(i);
                Object thatVal = that.vals.get(i);

                if (thisVal == null && thatVal == null) {
                    continue;
                }

                if (thisVal == null || thatVal == null || !thisVal.equals(thatVal)) {
                    return false;
                }
            }
            return true;
        }

        public override String toString() {
            return JSON.serialize(this.vals);
        }
    }

    /** 
     * Order a list of SObjects by the type of each record. This is useful
     * before performing a DML operation on a list of generic SObjects.
     */
    public static List<SObject> orderByType(List<SObject> records) {
        Map<SObjectType,List<SObject>> recordsByType = new Map<SObjectType,List<SObject>>();
        for (SObject record: records) {
            SObjectType type = record.getSObjectType();
            List<SObject> it = recordsByType.get(type);
            if (it == null) {
                it = new List<SObject>();
                recordsByType.put(type, it);
            }
            it.add(record);
        }
        List<SObject> result = new List<SObject>();
        for (List<SObject> it: recordsByType.values()) {
            result.addAll(it);
        }
        return result;
    }

    private static String formatPrefix(String prefix) {
        return String.isBlank(prefix) ? '' : (prefix + (prefix.endsWith('.') ? '' : '.'));
    }

    /**
     * Prepend a path prefix to all of the fields in the set.
     */
    public static Set<String> prefixFields(Set<String> fields, String prefix) {
        return prefixFields(prefix, fields);
    }

    /**
     * Prepend a path prefix to all of the fields in the set.
     */
    public static Set<String> prefixFields(String prefix, Set<String> fields) {
        Set<String> result = new Set<String>();
        prefix = formatPrefix(prefix);
        for (String field: fields) {
            result.add(prefix+field);
        }
        return result;
    }

    /**
     * Prepend a path prefix to a single field
     */
    public static String prefixField(String prefix, String field) {
         return formatPrefix(prefix) + field;
    }

    public interface Predicate {
        Boolean matches(SObject record);
    }

    private class StringFieldInSetPredicate implements Predicate {
        private final String field;
        private final Set<String> values;

        public StringFieldInSetPredicate(String field, Set<String> values) {
            this.field = field;
            this.values = values;
        }

        public Boolean matches(SObject record) {
            return values.contains((String)getField(record, field));
        }
    }

    private class IdFieldInSetPredicate implements Predicate {
        private final String field;
        private final Set<Id> ids;

        public IdFieldInSetPredicate(String field, Set<Id> ids) {
            this.field = field;
            this.ids = ids;
        }

        public Boolean matches(SObject record) {
            return ids.contains((Id)getField(record, field));
        }
    }

    private class FieldEqualsValuePredicate implements Predicate {
        private final String field;
        private final Object value;

        public FieldEqualsValuePredicate(String field, Object value) {
            this.field = field;
            this.value = value;
        }

        public Boolean matches(SObject record) {
            return getField(record, field) == value;
        }
    }

    private class NotPredicate implements Predicate {
        private final Predicate wrapped;

        public NotPredicate(Predicate wrapped) {
            this.wrapped = wrapped;
        }

        public Boolean matches(SObject record) {
            return !wrapped.matches(record);
        }
    }
}