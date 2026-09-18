# HopeGestion Mobile — Mapping Web → React Native

Ce document indique comment traduire chaque élément du prototype web en composants React Native.

## Bibliothèques recommandées

| Usage web | Équivalent React Native |
|-----------|------------------------|
| React DOM | `react-native` |
| Icônes `lucide-react` | `lucide-react-native` |
| Routage `tanstack/react-router` | `@react-navigation/native` + `@react-navigation/bottom-tabs` |
| État local `useState` | `useState` (identique) |
| Formulaires | `react-hook-form` (fonctionne en RN) |
| Validation | `zod` (identique) |
| Date | `date-fns` (identique) |

## Composants web → React Native

| Composant web | Composant RN | Notes |
|---------------|--------------|-------|
| `<div>` | `<View>` | Conteneur de base |
| `<p>`, `<span>`, `<h1>`… | `<Text>` | Tout texte doit être dans `<Text>` |
| `<button>` | `<TouchableOpacity>` ou `<Pressable>` | `<Button>` RN est très basique |
| `<input>` | `<TextInput>` | `keyboardType`, `placeholder`, `value`, `onChangeText` |
| `<select>` | `@react-native-picker/picker` ou menu custom | Ou `@gorhom/bottom-sheet` |
| `<textarea>` | `<TextInput multiline numberOfLines={4} />` | |
| `<img>` | `<Image>` | `source={{ uri }}` ou `require(...)` |
| `<label>` | `<View>` + `<Text>` | Pas d’équivalent direct |
| `<form>` | `<View>` | Gérer `onSubmit` via un bouton |
| `<nav>` | `<View>` | Bottom tab bar custom ou `@react-navigation/bottom-tabs` |
| `<section>` | `<View>` | Sémantique uniquement web |

## Styles

| Web (Tailwind) | React Native | Exemple |
|----------------|--------------|---------|
| `flex` | `flex: 1` | `{ flex: 1 }` |
| `flex-col` | `flexDirection: 'column'` | `{ flexDirection: 'column' }` |
| `items-center` | `alignItems: 'center'` | |
| `justify-between` | `justifyContent: 'space-between'` | |
| `gap-2` (8 px) | `gap: 8` | |
| `p-4` (16 px) | `padding: 16` | |
| `rounded-2xl` (16 px) | `borderRadius: 16` | |
| `bg-card` | `backgroundColor: '#FFFFFF'` | Voir design-system.md |
| `text-primary` | `color: '#009A9F'` | |
| `shadow-soft` | `elevation: 4` (Android) + `shadow*` (iOS) | |
| `border` | `borderWidth: 1` | |

Exemple de StyleSheet :

```tsx
import { StyleSheet, View, Text } from 'react-native';

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#D4E0DE',
    padding: 12,
    shadowColor: '#1A2E2A',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.08,
    shadowRadius: 24,
    elevation: 4,
  },
  title: {
    fontFamily: 'IBMPlexSans-SemiBold',
    fontSize: 21,
    color: '#1A2E2A',
  },
});
```

## Icônes

```tsx
import { Home, Building2, Users, ArrowUpRight, FileText, Plus } from 'lucide-react-native';

<Home size={17} color="#009A9F" />
```

## Navigation

Utiliser `@react-navigation/bottom-tabs` pour les 5 onglets :

```tsx
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
const Tab = createBottomTabNavigator();

<Tab.Navigator>
  <Tab.Screen name="Accueil" component={HomeScreen} />
  <Tab.Screen name="Biens" component={PropertiesScreen} />
  <Tab.Screen name="Contacts" component={ContactsScreen} />
  <Tab.Screen name="Finances" component={FinancesScreen} />
  <Tab.Screen name="Docs" component={DocumentsScreen} />
</Tab.Navigator>
```

Pour les formulaires en plusieurs étapes, utiliser `@react-navigation/native-stack` en mode modal ou un wizard interne avec `useState`.

## Formulaires

### Champ texte

```tsx
<TextInput
  value={name}
  onChangeText={setName}
  placeholder="Ex : Résidence Les Palmiers"
  style={styles.input}
/>
```

### Sélecteur

```tsx
import { Picker } from '@react-native-picker/picker';

<Picker selectedValue={type} onValueChange={setType}>
  <Picker.Item label="Immeuble collectif" value="Immeuble collectif" />
  ...
</Picker>
```

### Switch

```tsx
import { Switch } from 'react-native';

<Switch value={installments} onValueChange={setInstallments} />
```

### Image picker

```tsx
import * as ImagePicker from 'expo-image-picker';

const pickImage = async () => {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsMultipleSelection: true,
    quality: 0.8,
  });
  if (!result.canceled) {
    setPhotos(result.assets.map(a => a.uri));
  }
};
```

## Graphique

Le graphique du dashboard est un simple bar chart. Options en React Native :
- `react-native-gifted-charts` (recommandé, simple)
- `victory-native`
- Implémentation custom avec `<View>` + `height` dynamique

Exemple custom :

```tsx
{data.map(d => (
  <View key={d.day} style={{ alignItems: 'center' }}>
    <View style={{ flexDirection: 'row', alignItems: 'flex-end', gap: 4, height: 96 }}>
      <View style={{ width: 12, height: `${d.in}%`, backgroundColor: '#009A9F', borderRadius: 4 }} />
      <View style={{ width: 12, height: `${Math.max(24, d.in - 25)}%`, backgroundColor: 'rgba(107,125,122,0.25)', borderRadius: 4 }} />
    </View>
    <Text>{d.day}</Text>
  </View>
))}
```

## Bottom sheet / Action rapide

Utiliser `@gorhom/bottom-sheet` pour le menu `Que créer ?` :

```tsx
import BottomSheet from '@gorhom/bottom-sheet';

<BottomSheet ref={sheetRef} snapPoints={['40%']} index={-1}>
  <View style={styles.sheetContent}>
    <Text>ACTION RAPIDE</Text>
    <Text>Que créer ?</Text>
    {/* grille 2x2 */}
  </View>
</BottomSheet>
```

## Points d’attention

- Toutes les valeurs de style sont des nombres, pas des chaînes (sauf `fontFamily`).
- Les couleurs doivent être en HEX/RGB, pas en OKLCH (RN ne comprend pas OKLCH).
- Les ombres iOS utilisent `shadowColor/shadowOffset/shadowOpacity/shadowRadius` ; Android utilise `elevation`.
- Prévoir `SafeAreaView` pour les encoches et la bottom nav.
- Les images locales utilisent `require('./assets/...')` ; les images distantes utilisent `{ uri: '...' }`.
